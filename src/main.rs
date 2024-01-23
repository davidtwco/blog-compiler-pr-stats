use git2::{Oid, Repository};
use octocrab::params::State;
use rusqlite::Connection;
use std::time::Duration;

const DB_PATH: &'static str = "db.sqlite";
const REPO_ORG: &'static str = "rust-lang";
const REPO_NAME: &'static str = "rust";
const LOCAL_REPO_PATH: &'static str = "./rust";

#[tokio::main]
async fn main() {
    let conn = Connection::open(DB_PATH).expect("create database");
    conn.execute_batch(include_str!("create.sql"))
        .expect("create tables");

    let repository = Repository::open(LOCAL_REPO_PATH).expect("open local repository");

    let mut page_num = std::env::var("PR_STATS_PAGE")
        .map(|v| u32::from_str_radix(&v, 10).expect("parse page number"))
        .unwrap_or(1);
    let personal_token = std::env::var("GH_TOKEN").expect("no github token");
    let octocrab = octocrab::OctocrabBuilder::default()
        .personal_token(personal_token)
        .build()
        .expect("building octocrab");
    dbg!(page_num);
    let mut current_page = Some(
        octocrab
            .pulls(REPO_ORG, REPO_NAME)
            .list()
            .per_page(100)
            .page(page_num)
            .state(State::All)
            .send()
            .await
            .expect("fetch pull requests"),
    );

    while let Some(page) = current_page {
        for pr in page.items {
            dbg!(pr.number);

            if let Some(user) = &pr.user {
                conn.execute(
                    include_str!("insert_contributor.sql"),
                    (user.login.as_str(),),
                )
                .expect("insert contributor");
            }

            let manually_assigned = pr
                .body
                .or(pr.body_text)
                .map(|b| b.contains("\nr?"))
                .unwrap_or(false);

            conn.execute(
                include_str!("insert_pr.sql"),
                (
                    pr.number,
                    pr.user.map(|u| u.login),
                    pr.created_at,
                    pr.closed_at,
                    pr.merged_at,
                    manually_assigned,
                ),
            )
            .expect("insert pr");

            if let Some(labels) = &pr.labels {
                for label in labels {
                    conn.execute(include_str!("insert_label.sql"), (label.name.as_str(),))
                        .expect("insert label");
                    conn.execute(
                        include_str!("add_label_to_pr.sql"),
                        (pr.number, label.name.as_str()),
                    )
                    .expect("add label to pr");
                }
            }

            let add_assignee = |name: &str| {
                conn.execute(include_str!("insert_contributor.sql"), (name,))
                    .expect("insert contributor");
                conn.execute(include_str!("add_assignee_to_pr.sql"), (pr.number, name))
                    .expect("add assignee to pr");
            };
            if let Some(assignee) = &pr.assignee {
                add_assignee(assignee.login.as_str());
            }
            if let Some(assignees) = &pr.assignees {
                for assignee in assignees {
                    add_assignee(assignee.login.as_str());
                }
            }

            let add_file = |path: &str| {
                conn.execute(include_str!("insert_file.sql"), (path,))
                    .expect("insert file");
                conn.execute(include_str!("add_file_to_pr.sql"), (pr.number, path))
                    .expect("add file to pr");
            };
            if let Some(merged) = pr.merge_commit_sha {
                let oid = Oid::from_str(&merged).expect("create oid");
                if let Ok(merge_commit) = repository.find_commit(oid) {
                    let first_parent = merge_commit.parents().next().expect("first parent");
                    let diff = repository
                        .diff_tree_to_tree(
                            merge_commit.tree().ok().as_ref(),
                            first_parent.tree().ok().as_ref(),
                            None,
                        )
                        .expect("diff");
                    for delta in diff.deltas() {
                        if let Some(old_file) = delta.old_file().path() {
                            add_file(old_file.to_str().unwrap());
                        }
                        if let Some(new_file) = delta.new_file().path() {
                            add_file(new_file.to_str().unwrap());
                        }
                    }
                }
            }
        }

        page_num += 1;
        dbg!(page_num, &page.next);
        current_page = octocrab.get_page(&page.next).await.expect("next page");

        // Sleep for 100ms to try avoid rate limiting.
        tokio::time::sleep(Duration::from_millis(100)).await;
    }
}
