This is a CLI / REPL for facilitating the job application process.

I'll be honest, building this was probably a good example of procrastination.

But regardless:

Install:

- clone the repo
- cd in
- run `bundle`
- `cp env.example .env` and customize

_i should mention that I'm testing / building this for Ubuntu systems, and I'm not
sure how well it will work on non-Linux. It's likely to work just fine on OSX_.

Start:

`pry -r ./app.rb -e 'autoload'`

Commands:

- installers, these are only necessary for some functions
  - `install(:google)` to install the Google CLI
  - `install(:chromedriver)` to install the chromedriver (needed for selenium)
- `google_search "<term>"` - after this is run, a number of other commands are available
  and will be printed by the REPL.
- `search_<job_site> "<term>"` the available job sites are `angel_list`, `stack_overflow`,
`github`, and `whos_hiring`. AngelList and WhosHiring generally have the most results.
All of these methods accept an (optional) options hash as well as callback. The options hash is
situation-specific (see [app/cli_helpers.rb](./app/cli_helpers.rb) but generally accepts
`async` and `headless` boolean flags which by default are enabled. Each of these methods
creates `Job` records in DataMapper/SQLite.
- `search_crunchbase "term"` takes a screenshot of the crunchbase page for a specific company.
Also accepts the `async` and `headless` options as well as a callback. The callback is invoked
with the local file path of the screenshot (a tempfile path).
- `apply_to_jobs` starts a repl that shows the jobs with a nil `status` column and prompts
the user to take action, either by looking up more details, making a comment/tag, or updating
the `status`. These options are printed in the REPL.
