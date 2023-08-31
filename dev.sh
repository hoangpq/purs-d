lsof -ti :3456 | xargs kill -9
deno run npm:concurrently@8.2.1 "spago build --watch" "deno run -A --unstable --watch main.js"
