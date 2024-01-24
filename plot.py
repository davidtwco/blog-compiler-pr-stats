from datetime import datetime
import os
import plotly.graph_objects as go
import pandas
import numpy as np

if not os.path.exists("images"):
    os.mkdir("images")

fromtimestamp = np.vectorize(lambda e: datetime.fromtimestamp(e))

# week-by-week variations make the graph very noisy, doing a rolling average should make the trends
# clearer
def smooth(arr, N=4):
    return pandas.Series(arr).rolling(window=N).mean().iloc[N-1:].values

data = pandas.read_csv("./data/prs_week_compiler.csv")
dates = fromtimestamp(np.array(data["date"]))
count = smooth(np.array(data["count"]))

data_manually = pandas.read_csv("./data/prs_week_compiler_manually.csv")
dates_manually = fromtimestamp(np.array(data_manually["date"]))
count_manually = smooth(np.array(data_manually["count"]))

data_team = pandas.read_csv("./data/prs_week_compiler_team.csv")
dates_team = fromtimestamp(np.array(data_team["date"]))
count_team = smooth(np.array(data_team["count"]))

fig = go.Figure()
fig.add_trace(go.Scatter(x=dates, y=count, mode='lines', name='prs/wk'))
fig.add_trace(go.Scatter(x=dates_manually, y=count_manually, mode='lines', name='prs/wk (r?)'))
fig.add_trace(go.Scatter(x=dates_team, y=count_team, mode='lines', name='prs/wk (team)'))
fig.update_layout(template='plotly_white', title = 'Per-week pull requests to compiler team')
fig.write_image("images/per_week_compiler.png", width=1000, height=800)
# fig.show()

data = pandas.read_csv("./data/prs_week_types.csv")
dates = fromtimestamp(np.array(data["date"]))
count = smooth(np.array(data["count"]))

data_manually = pandas.read_csv("./data/prs_week_types_manually.csv")
dates_manually = fromtimestamp(np.array(data_manually["date"]))
count_manually = smooth(np.array(data_manually["count"]))

data_team = pandas.read_csv("./data/prs_week_types_team.csv")
dates_team = fromtimestamp(np.array(data_team["date"]))
count_team = smooth(np.array(data_team["count"]))

fig = go.Figure()
fig.add_trace(go.Scatter(x=dates, y=count, mode='lines', name='prs/wk'))
fig.add_trace(go.Scatter(x=dates_manually, y=count_manually, mode='lines', name='prs/wk (r?)'))
fig.add_trace(go.Scatter(x=dates_team, y=count_team, mode='lines', name='prs/wk (team)'))
fig.update_layout(template='plotly_white', title = 'Per-week pull requests to types team')
fig.write_image("images/per_week_types.png", width=1000, height=800)
# fig.show()

data = pandas.read_csv("./data/total_over_time.csv")
dates = fromtimestamp(np.array(data["date"]))
cumulative = np.array(data["cumulative"])

data_manually = pandas.read_csv("./data/total_over_time_manually.csv")
dates_manually = fromtimestamp(np.array(data_manually["date"]))
cumulative_manually = np.array(data_manually["cumulative"])

fig = go.Figure()
fig.add_trace(go.Scatter(x=dates, y=cumulative, mode='lines', name='prs'))
fig.add_trace(go.Scatter(x=dates_manually, y=cumulative_manually, mode='lines', name='r? prs'))
fig.update_layout(template='plotly_white', title = 'Total PRs to rustc')
fig.write_image("images/cumulative_total.png", width=1000, height=800)
# fig.show()

data = pandas.read_csv("./data/reviewers.csv")
dates = fromtimestamp(np.array(data["date"]))
compiler_reviewers = np.array(data["compiler_reviewers"])
contributor_reviewers = np.array(data["contributor_reviewers"])
types_reviewers = np.array(data["types_reviewers"])
compiler_size = np.array(data["compiler_size"])
contributor_size = np.array(data["contributor_size"])
types_size = np.array(data["types_size"])

fig = go.Figure()
fig.add_trace(go.Scatter(x=dates, y=compiler_size + contributor_size, mode='lines', name='team size'))
fig.add_trace(go.Scatter(x=dates, y=compiler_reviewers, mode='lines', name='member reviewers', stackgroup='reviewers'))
fig.add_trace(go.Scatter(x=dates, y=contributor_reviewers, mode='lines', name='contributor reviewers', stackgroup='reviewers'))
fig.update_layout(template='plotly_white', title = 't-compiler team size and reviewer count')
fig.write_image("images/team_size_compiler.png", width=1000, height=800)
# fig.show()

fig = go.Figure()
fig.add_trace(go.Scatter(x=dates, y=types_size[45:], mode='lines', name='team size'))
fig.add_trace(go.Scatter(x=dates, y=types_reviewers[45:], mode='lines', name='reviewers', stackgroup='reviewers'))
fig.update_layout(template='plotly_white', title = 't-types team size and reviewer count')
fig.write_image("images/team_size_types.png", width=1000, height=800)
# fig.show()

data = pandas.read_csv("./data/assignments_per_reviewer.csv")
dates = fromtimestamp(np.array(data["date"]))
count = smooth(np.array(data["count"]))
num_reviewers = np.array(data["total_reviewers"])
per_reviewer = smooth(np.array(data["per_reviewer"]))

fig = go.Figure()
fig.add_trace(go.Scatter(x=dates, y=count, mode='lines', name='prs/wk (non-r?)'))
fig.add_trace(go.Scatter(x=dates, y=num_reviewers, mode='lines', name='no. reviewer'))
fig.add_trace(go.Scatter(x=dates, y=per_reviewer, mode='lines', name='assigned prs/reviewer'))
fig.update_layout(template='plotly_white', title = 'Per-week PRs assigned to each reviewer')
fig.write_image("images/per_week_assignments.png", width=1000, height=800)
# fig.show()

data = pandas.read_csv("./data/average_review_time.csv")
dates = fromtimestamp(np.array(data["date"]))
time_open = smooth(np.array(data["time_open"]))

fig = go.Figure()
fig.add_trace(go.Scatter(x=dates[5:], y=time_open[5:], mode='lines', name='hrs open'))
fig.update_layout(template='plotly_white', title = 'Average no. hours from open until merge by creation week')
fig.write_image("images/average_review_time.png", width=1000, height=800)
# fig.show()
