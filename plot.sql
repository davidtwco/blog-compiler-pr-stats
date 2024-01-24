DROP TABLE IF EXISTS temp.trimmed_prs;
DROP TABLE IF EXISTS temp.compiler_only;
DROP TABLE IF EXISTS temp.compiler_only_by_team;
DROP TABLE IF EXISTS temp.types_only;
DROP TABLE IF EXISTS temp.types_only_by_team;
DROP TABLE IF EXISTS temp.by_week_with_num_reviewers_compiler;

CREATE TEMPORARY TABLE trimmed_prs AS
SELECT pr.*, pf.file_path FROM pr
INNER JOIN pr_files AS pf ON pf.pr_id = pr.id
WHERE unixepoch(created_at) > 1451606400;

CREATE TEMPORARY TABLE compiler_only AS 
SELECT * FROM trimmed_prs
WHERE 
	file_path LIKE 'compiler/%' OR
	file_path LIKE 'tests/assembly/%' OR
	file_path LIKE 'tests/codegen/%' OR
	file_path LIKE 'tests/coverage-map/%' OR
	file_path LIKE 'tests/coverage/%' OR
	file_path LIKE 'tests/debuginfo/%' OR
	file_path LIKE 'tests/incremental/%' OR
	file_path LIKE 'tests/mir-opt/%' OR
	file_path LIKE 'tests/run-coverage/%' OR
	file_path LIKE 'tests/run-make-fulldeps/%' OR
	file_path LIKE 'tests/run-make/%' OR
	file_path LIKE 'tests/ui/%' OR
	file_path LIKE 'tests/ui-fulldeps/%' OR
	file_path LIKE 'src/rustc_%' OR
	file_path LIKE 'src/librustc_%' OR
	file_path LIKE 'src/test/assembly/%' OR
	file_path LIKE 'src/test/codegen/%' OR
	file_path LIKE 'src/test/codegen-units/%' OR
	file_path LIKE 'src/test/compile-fail/%' OR
	file_path LIKE 'src/test/compile-fail-fulldeps/%' OR
	file_path LIKE 'src/test/debuginfo/%' OR
	file_path LIKE 'src/test/incremental/%' OR
	file_path LIKE 'src/test/incremental-fulldeps/%' OR
	file_path LIKE 'src/test/mir-opt/%' OR
	file_path LIKE 'src/test/parse-fail/%' OR
	file_path LIKE 'src/test/pretty/%' OR
	file_path LIKE 'src/test/run-make/%' OR
	file_path LIKE 'src/test/run-make-fulldeps/%' OR
	file_path LIKE 'src/test/run-pass/%' OR
	file_path LIKE 'src/test/run-pass-fulldeps/%' OR
	file_path LIKE 'src/test/run-fail/%' OR
	file_path LIKE 'src/test/ui/%' OR
	file_path LIKE 'src/test/ui-fulldeps/%' OR
	file_path LIKE 'src/libsyntax%'
GROUP BY id;

CREATE TEMPORARY TABLE types_only AS 
SELECT * FROM compiler_only
WHERE
	file_path LIKE 'compiler/rustc_hir_analysis%' OR
	file_path LIKE 'compiler/rustc_middle/src/traits%' OR
	file_path LIKE 'compiler/rustc_middle/src/ty%' OR
	file_path LIKE 'compiler/rustc_trait_selection%' OR
	file_path LIKE 'compiler/rustc_traits%' OR
	file_path LIKE 'compiler/rustc_type_ir%'
GROUP BY id;

CREATE TEMPORARY TABLE types_only_by_team AS 
SELECT * FROM types_only
WHERE
	author_name = "aliemjay" OR
	author_name = "BoxyUwU" OR
	author_name = "compiler-errors" OR
	author_name = "jackh726" OR
	author_name = "lcnr" OR
	author_name = "nikomatsakis" OR
	author_name = "oli-obk" OR
	author_name = "spastorino";

CREATE TEMPORARY TABLE compiler_only_by_team AS 
SELECT * FROM compiler_only
WHERE
	author_name = "Aaron1011" OR
	author_name = "Aatch" OR
	author_name = "apiraino" OR
	author_name = "arielb1" OR
	author_name = "b-naber" OR
	author_name = "bjorn3" OR
	author_name = "bkoropoff" OR
	author_name = "BoxyUwU" OR
	author_name = "Centril" OR
	author_name = "chenyukang" OR
	author_name = "cjgillot" OR
	author_name = "compiler-errors" OR
	author_name = "cramertj" OR
	author_name = "cuviper" OR
	author_name = "davidtwco" OR
	author_name = "dotdash" OR
	author_name = "durin42" OR
	author_name = "ecstatic-morse" OR
	author_name = "eddyb" OR
	author_name = "eholk" OR
	author_name = "est31" OR
	author_name = "estebank" OR
	author_name = "fee1-dead" OR
	author_name = "flodiebold" OR
	author_name = "fmease" OR
	author_name = "jackh726" OR
	author_name = "jseyfried" OR
	author_name = "lcnr" OR
	author_name = "LeSeulArtichaut" OR
	author_name = "lqd" OR
	author_name = "Mark-Simulacrum" OR
	author_name = "matklad" OR
	author_name = "matthewjasper" OR
	author_name = "michaelwoerister" OR
	author_name = "Nadrieril" OR
	author_name = "nagisa" OR
	author_name = "nikic" OR
	author_name = "nikomatsakis" OR
	author_name = "nikomatsakis" OR
	author_name = "Nilstrieb" OR
	author_name = "nnethercote" OR
	author_name = "nrc" OR
	author_name = "oli-obk" OR
	author_name = "petrochenkov" OR
	author_name = "pnkfelix" OR
	author_name = "RalfJung" OR
	author_name = "saethlin" OR
	author_name = "scalexm" OR
	author_name = "SparrowLii" OR
	author_name = "spastorino" OR
	author_name = "TaKO8Ki" OR
	author_name = "the8472" OR
	author_name = "tmandry" OR
	author_name = "tmiasko" OR
	author_name = "varkor" OR
	author_name = "varkor" OR
	author_name = "WaffleLapkin" OR
	author_name = "wesleywiser" OR
	author_name = "Xanewok" OR
	author_name = "zackmdavis" OR
	author_name = "Zoxc";


-- prs/week per reviewer compiler only
CREATE TEMPORARY TABLE by_week_with_num_reviewers_compiler AS
SELECT
	unixepoch(created_at) AS "date",
	COUNT(id) as "count",
	(
		SELECT m.count 
    	FROM compiler_reviewers AS m
    	WHERE m.date <= created_at
    	ORDER BY m.date DESC
    	LIMIT 1
	) AS "compiler_reviewers_",
	(
		SELECT c.count 
    	FROM contributor_reviewers AS c
    	WHERE c.date <= created_at
    	ORDER BY c.date DESC
    	LIMIT 1
	) AS "contributor_reviewers_"
FROM temp.compiler_only
WHERE manually_assigned == 0
GROUP BY strftime('%Y-%W', created_at);


-- sanity checks:
-- check pr counts
SELECT * FROM pr WHERE merged_at IS NULL AND closed_at IS NOT NULL AND unixepoch(created_at) > 1451606400;
SELECT * FROM pr WHERE merged_at IS NOT NULL AND unixepoch(created_at) > 1451606400;
SELECT * FROM pr WHERE unixepoch(created_at) > 1451606400;
SELECT * FROM temp.compiler_only;

-- check paths excluded by compiler_only
SELECT DISTINCT file_path
FROM trimmed_prs AS tp
WHERE id NOT IN (SELECT id FROM temp.compiler_only)
ORDER BY file_path ASC;


-- total_over_time.csv
SELECT unixepoch(created_at) AS "date", ROW_NUMBER() OVER() AS "cumulative"
FROM temp.compiler_only;

-- total_over_time_manually.csv
SELECT unixepoch(created_at) AS "date", ROW_NUMBER() OVER() AS "cumulative"
FROM temp.compiler_only
WHERE manually_assigned == 1;

-- prs_week_compiler.csv
SELECT unixepoch(created_at) AS "date", COUNT(id) as "count"
FROM temp.compiler_only
GROUP BY strftime('%Y-%W', created_at);

-- prs_week_compiler_manually.csv
SELECT unixepoch(created_at) AS "date", COUNT(id) as "count"
FROM temp.compiler_only
WHERE manually_assigned == 1
GROUP BY strftime('%Y-%W', created_at);

-- prs_week_compiler_team.csv
SELECT unixepoch(created_at) AS "date", COUNT(id) as "count"
FROM temp.compiler_only_by_team
GROUP BY strftime('%Y-%W', created_at);

-- prs_week_types.csv
SELECT unixepoch(created_at) AS "date", COUNT(id) as "count"
FROM temp.types_only
GROUP BY strftime('%Y-%W', created_at);

-- prs_week_types_manually.csv
SELECT unixepoch(created_at) AS "date", COUNT(id) as "count"
FROM temp.types_only
WHERE manually_assigned == 1
GROUP BY strftime('%Y-%W', created_at);

-- prs_week_types_team.csv
SELECT unixepoch(created_at) AS "date", COUNT(id) as "count"
FROM temp.types_only_by_team
GROUP BY strftime('%Y-%W', created_at);

-- reviewers.csv
SELECT 
	unixepoch(tstamp) AS "date",
	(
		SELECT m.count 
    	FROM compiler_reviewers AS m
    	WHERE m.date <= tstamp
    	ORDER BY m.date DESC
    	LIMIT 1
	) AS "compiler_reviewers",
	(
		SELECT c.count 
    	FROM contributor_reviewers AS c
    	WHERE c.date <= tstamp
    	ORDER BY c.date DESC
    	LIMIT 1
	) AS "contributor_reviewers",
	(
		SELECT t.count 
    	FROM types_reviewers AS t
    	WHERE t.date <= tstamp
    	ORDER BY t.date DESC
    	LIMIT 1
	) AS "types_reviewers",
	(
		SELECT ms.count 
    	FROM compiler_size AS ms
    	WHERE ms.date <= tstamp
    	ORDER BY ms.date DESC
    	LIMIT 1
	) AS "compiler_size",
	(
		SELECT cs.count 
    	FROM contributor_size AS cs
    	WHERE cs.date <= tstamp
    	ORDER BY cs.date DESC
    	LIMIT 1
	) AS "contributor_size",
	(
		SELECT ts.count 
    	FROM types_size AS ts
    	WHERE ts.date <= tstamp
    	ORDER BY ts.date DESC
    	LIMIT 1
	) AS "types_size"
FROM (
	SELECT m.date AS "tstamp" FROM compiler_reviewers AS m
	UNION 
	SELECT c.date AS "tstamp" FROM contributor_reviewers AS c
	UNION
	SELECT t.date AS "tstamp" FROM types_reviewers AS t
	UNION
	SELECT ms.date AS "tstamp" FROM compiler_size AS ms
	UNION 
	SELECT cs.date AS "tstamp" FROM contributor_size AS cs
	UNION
	SELECT ts.date AS "tstamp" FROM types_size AS ts
);

-- assignments_per_reviewer.csv
SELECT 
	date,
	count,
	(CASE WHEN compiler_reviewers_ IS NULL THEN 0 ELSE compiler_reviewers_ END) + (CASE WHEN contributor_reviewers_ IS NULL then 0 ELSE contributor_reviewers_ END) AS "total_reviewers",
	count / ((CASE WHEN compiler_reviewers_ IS NULL THEN 0 ELSE compiler_reviewers_ END) + (CASE WHEN contributor_reviewers_ IS NULL then 0 ELSE contributor_reviewers_ END)) AS "per_reviewer"
FROM temp.by_week_with_num_reviewers_compiler
WHERE compiler_reviewers_ IS NOT NULL;

-- average_review_time.csv
SELECT unixepoch(created_at) AS "date", AVG(strftime('%s', merged_at) - strftime('%s', created_at)) / 2400 AS "time_open"
FROM temp.compiler_only
GROUP BY strftime('%Y-%W', created_at);
