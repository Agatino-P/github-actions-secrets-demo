
GitHub Actions:
/
Claude finished the response
Today's topic is GitHub Actions Secrets. I want first a quick introduction, then if it makes sense, I want to create a sample repository under my github account to practice with those. Maybe in a different "folder" from my other projects. I care not too much about the content of the repo, the simpler the better, even if it's just a shell script. If we ant to use real code a simple dotnet console app would be fine.
But first of all, the idea behind it, if ti makes sense to compare it with K8S secrets, config maps etc

19:50

Structured GitHub Actions Secrets concept and mapped practical implementation strategy
Structured GitHub Actions Secrets concept and mapped practical implementation strategy
GitHub Actions Secrets are, at their core, encrypted values you store in GitHub so your workflows can use sensitive data (API keys, tokens, passwords, connection strings) without hard-coding them into the repo. When a workflow runs, GitHub injects them and masks them in the logs so they don't leak into output.

A few things I'm confident about on the concept:

They're encrypted before storage. When you set a secret via the API, it's encrypted client-side using a libsodium "sealed box" with a public key GitHub gives you; GitHub never sees the plaintext in transit. (Through the web UI this happens for you.)
You reference them in a workflow with the expression ${{ secrets.MY_SECRET }}, typically mapping them into an env: block or passing them to a step.
They come in scopes: organization, repository, and environment secrets (environment secrets can add protections like required reviewers before they're accessible).
GitHub also has Variables, which are the non-sensitive counterpart: plaintext, visible in the UI, referenced as ${{ vars.MY_VAR }}. These are the natural analog to config, not secrets.
I'd flag a couple of things rather than guess: the exact size limit per secret and the maximum number of secrets per scope are figures I won't state from memory, since GitHub adjusts these — worth checking the current GitHub Actions docs if those limits matter to you. The conceptual model above has been stable, but the UI and specific quotas may have shifted since my knowledge cutoff.

Comparing with Kubernetes
The mental model maps reasonably well, with one important caveat:

Concept	Kubernetes	GitHub Actions
Sensitive data	Secret	Secret
Non-sensitive config	ConfigMap	Variable
How it's consumed	Env var or mounted as a file/volume	Env var / expression only
Scope/boundary	Namespace	Org / repo / environment
At-rest protection	base64 by default; encryption is opt-in	Encrypted by default
The caveat worth emphasizing: a Kubernetes Secret is not encrypted by default — it's only base64-encoded, which is encoding, not security. Encryption at rest in etcd has to be explicitly configured. GitHub Actions secrets, by contrast, are encrypted as the default behavior. So the names line up (Secret ↔ Secret, ConfigMap ↔ Variable), but the security guarantees out-of-the-box differ.

The other real difference is consumption: in K8S you can mount a Secret as a file inside a pod (handy for config files, TLS certs). GitHub Actions has no file-mount equivalent — a secret is a value you map into an environment variable or pass to a command. If you need a file, you write the secret's value into a file as a workflow step.

So the comparison does make sense, as long as you treat it as "same roles, different mechanics and different default guarantees."

On the practice repo
One honest limitation: I can't create a repository directly under your GitHub account — I don't have access to your GitHub credentials. What I can do is generate all the files (the sample app, the workflow YAML, a README) here, and give you the exact commands to create the repo and push, so it's a two-minute step on your side.

On the "different folder" idea: GitHub personal accounts don't have folders — repos are a flat list. If you want real grouping separate from your other projects, the options are either just a clearly-named standalone repo (simplest), or a separate GitHub Organization (free) that holds your practice/throwaway repos. I'd suggest a standalone repo unless you specifically want the org boundary.

Given your "simpler the better" steer, my default plan is a tiny shell script workflow that reads a secret and a variable and prints whether they were received (without exposing the secret), since that demonstrates the whole secrets mechanism with zero build tooling. I can just as easily do the dotnet console app version if you'd prefer reading a secret via Environment.GetEnvironmentVariable in actual C#.

Before I build the files, two quick choices so I generate the right thing:

Q: Which sample app should the practice repo use?
A: Shell script (simplest)

Q: How do you want to group it?
A: Standalone repo

20:03

Architected shell script repo with workflow, secrets handling, and setup instructions
Architected shell script repo with workflow, secrets handling, and setup instructions
Shell script, standalone repo. I'll generate the full repo structure, then give you the exact commands to create it on GitHub and push.


Orchestrated file creation for shell script repository
Orchestrated file creation for shell script repository
Here's the full repo. The tarball preserves the .github/workflows/ structure intact, so unpack that rather than copying files individually.

Push it to GitHub. Unpack the tarball, then from inside the folder run one of these. If you have the GitHub CLI (gh):

bash
tar -xzf github-actions-secrets-demo.tar.gz
cd github-actions-secrets-demo
git init -b main
git add .
git commit -m "Initial: GitHub Actions secrets demo"
gh repo create github-actions-secrets-demo --private --source=. --push
Or the plain-git way (create an empty repo named github-actions-secrets-demo on GitHub first, then):

bash
tar -xzf github-actions-secrets-demo.tar.gz
cd github-actions-secrets-demo
git init -b main
git add .
git commit -m "Initial: GitHub Actions secrets demo"
git remote add origin git@github.com:<your-username>/github-actions-secrets-demo.git
git push -u origin main
After pushing, follow the README: add the secret MY_SECRET and the variable MY_GREETING under Settings → Secrets and variables → Actions, then run the workflow from the Actions tab.

One expected quirk worth calling out: the push to main will trigger the first run before you've added the secret, so that first run fails on purpose with a clear "MY_SECRET is not set" message. Add the secret and variable, then re-run via Run workflow. That failure-then-success cycle is actually a useful thing to see.

Two honesty notes on the technical details:

I used actions/checkout@v4, which is a real, working version I'm confident in. GitHub may have released

Github actions secrets demo.tar
GZ 

Check secrets
SH 

Secrets demo
YML 

Readme
Document · MD 
Claude's response was interrupted.
as this is a POC I’d rather have the secret value echoed in clear text, to be able to compare it . It's not that it has any real value

20:05

Reconciled GitHub's masking behavior with educational demonstration needs
Reconciled GitHub's masking behavior with educational demonstration needs
Quick heads-up before I change it, because this is exactly the kind of thing where the result surprises people: GitHub will still mask it. Any value you've registered as a Secret gets redacted to *** in the run logs automatically — even if you echo "$MY_SECRET" directly. The masking happens at the log layer, not in your script, so you can't get a registered secret to print in clear text through a normal echo.

So the comparison you'll actually see is: the Variable prints in clear text, the Secret prints as ***. That contrast is the useful thing. Let me wire the script to echo both directly so you see it side by side.


Edited a file, ran a command, read a file
Edited a file, ran a command, read a file
Done. The script now echoes both directly, and the tarball is updated.

What you'll see in the run log:

Variable MY_GREETING : Hello from a GitHub Actions variable
Secret   MY_SECRET   : ***
The variable comes through verbatim; the secret is redacted to *** no matter how you print it. I also left a commented-out line at the bottom: if you uncomment the reversed-echo, you'll see the transformed value print in clear text — because GitHub's masking only matches the literal registered string. That's the honest lesson of the whole exercise: masking is a shallow backstop, not real protection, which is why the "never print real secrets" rule holds even though the log usually hides them.

One thing I'm not fully certain of and you can verify just by watching the run: if your throwaway secret value is extremely short or a common substring (say 1 or test), GitHub may also mask incidental occurrences of that string elsewhere in the log, which can look confusing. Using something distinctive like super-secret-123 avoids that.


Github actions secrets demo.tar
GZ 

Check secrets
SH 
I'm not sure to understand it, if I had a real application, that would net the secret value in clear at a certain point

20:07

Architected visual diagram illustrating secret lifecycle and exposure zones
Architected visual diagram illustrating secret lifecycle and exposure zones
Right — and that's the most important thing to get straight, so good question.

Yes: a real application needs the secret in clear text at the exact moment it uses it. An API key has to be sent to the API; a database password has to be handed to the database. The value is in plaintext in the process's memory and environment at runtime. That is unavoidable, and it is not what secrets management is trying to prevent.

What "secrets" protect is everything around that moment of use, not the moment itself. Three things specifically:

Storage — GitHub keeps the value encrypted at rest, and once you set it you can't read it back out through the UI or API (it's write-only; you can only overwrite or delete). So it isn't sitting in plaintext in your source code, your config files, or your git history.
Distribution — the value is only injected into authorized runs. For example, a pull request from a forked repo does not receive your secrets by default, so a stranger opening a PR can't make your workflow hand them the key.
Accidental logging — masking stops the value from spilling into the build log, which is often seen by more people than should ever see the secret (anyone on a public repo, all your teammates, archived CI artifacts).
So the goal isn't "the secret is never in clear text." It's "the clear-text value exists only inside the trusted, running job, only briefly, and only for code that's authorized to be there." Compare that to hardcoding the key in your script: then it's in clear text in source control, on every clone, in every log, forever, for everyone with repo access.

The honest limit falls right out of this: if an attacker can run their own code inside that trusted job — a malicious dependency, a compromised workflow step, a command injection — they can read the secret too, because at that point they're standing inside the same clear-text zone your app is. That's why "never print real secrets" and "don't pull in untrusted actions/steps" still matter even though the log normally hides the value.

Here's the lifecycle, with the one place clear text legitimately lives marked out:

This is the key thing to picture — the value is encrypted everywhere except one zone, and that zone is unavoidable:



Reading the diagram: the secret is encrypted everywhere except inside that dashed box. Decryption happens only when GitHub injects it into your authorized job, your code uses it (clear text — unavoidable), and from there it either flows out to the real service it's for, or, if it ever lands in the log, gets masked.

So your instinct was exactly right, and it's worth holding onto: "the secret is in clear text at some point" is true and intended. The discipline of secrets management isn't about preventing that moment — it's about shrinking it to the smallest, most-trusted place possible (one ephemeral job run) instead of letting it sprawl into source code, git history, and logs forever.

And the Kubernetes parallel holds one-to-one: a K8S Secret is decoded and handed to your pod, where the app reads it in clear text just the same. The Secret object guards storage and access (who can mount it, whether etcd encrypts it), not the runtime fact that the running container can read the value. Same model, same unavoidable clear-text moment, same point to the whole exercise.

screw that, what if I create a variable $mysecretstring and set it  "*"+${{ secrets.MY_SECRET }}+"*".
then echo $mysecretstring
?

20:11

Analyzed masking mechanism and evaluated proposed workaround's effectiveness
Analyzed masking mechanism and evaluated proposed workaround's effectiveness
Ha — that one won't work either, and why it doesn't is the actually-useful bit.

GitHub's masking is a literal find-and-replace on the log text: it scans for the exact registered secret value and swaps that substring for ***. Wrapping it in asterisks doesn't touch the secret's own characters — they still sit contiguously inside your string — so the masker finds them and redacts just that part. You'd see something like:

*****
which is your * + the masked *** + your *. The real value never surfaces.

What does slip past masking is anything that breaks the value up so the literal registered string no longer appears in the output — then there's nothing for the find-and-replace to match. Reversing it, or inserting a character between every character, does exactly that. That's the line already sitting commented-out in your script:

bash
echo "Reversed (NOT masked): $(echo -n "$MY_SECRET" | rev)"
Uncomment that and you'll see the reversed value in clear text, because 321-terces-repus doesn't match the registered super-secret-123.

So the contrast you can run side by side with your throwaway value: wrap-in-asterisks → still masked; reverse → leaks. That is the lesson, and it's why "never print real secrets" holds regardless of masking — masking is a shallow log filter, not protection. Anyone who can run code inside the job (or transform the value before it hits the log) has the plaintext anyway.

One thing I'm not fully certain about: the literal-value and simple-reversal behavior I'm confident in, but I'm less sure exactly which encodings GitHub might also auto-catch (I believe plain base64 is not auto-masked, but I wouldn't bet your understanding on my memory) — worth just running it with the dummy value to confirm rather than taking my word.

Want me to add both experiments as explicit steps in the script so the comparison prints in one run?

yes, add reversing and base64 and see what happens

20:13

Revised script to include reversing and base64 transformation experiments
Revised script to include reversing and base64 transformation experiments
Let me view the current script, then add the experiments.


Devised testing strategy and clarified masking behavior expectations
Devised testing strategy and clarified masking behavior expectations
Let me sanity-check the script runs cleanly (locally there's no masking — that only happens on GitHub's runners — but this confirms no syntax errors):


Ran 2 commands, read a file
Ran 2 commands, read a file
Added all three experiments. The local run above just proves the script executes — there's no masking locally, so everything prints in clear. The interesting part only happens on GitHub's runners.

What I'd predict you'll see in the actual GitHub Actions log (with the secret set to super-secret-123):

Secret   MY_SECRET   : ***
...
1. Wrapped     : ****
2. Reversed    : 321-terces-repus
3. Base64      : ???
Lines 1 and 2 I'm confident about: wrapped stays masked (the literal value is still in there as a contiguous substring), reversed leaks (the literal string no longer appears). Line 3, base64, is the one I told you I'm not sure about — so don't trust my guess, just read the log. The plausible outcomes are either it prints the base64 in clear (c3VwZXItc2VjcmV0LTEyMw==), meaning GitHub only masks the raw value, or it comes back as ***, meaning GitHub also registers common encodings of a secret.

If you want a tiebreaker either way, after the run check Settings → Secrets and variables → Actions isn't where the masking logic lives — the registration of additional forms (if any) happens at runtime, so the log is genuinely the authoritative test here. Run it and tell me what line 3 shows; I'm curious which way it lands, and it'll pin down a detail I'd otherwise be guessing at.

One caution for when you run it: since super-secret-123 is short and distinctive you'll get clean results, but if you ever swap in a value that happens to contain a common substring, masking can redact unrelated occurrences of that substring elsewhere in the log and muddy the experiment.


Check secrets
SH 

Github actions secrets demo.tar
GZ 
don't I need to lgin on github, will that bash script trigger it by default?

20:16

Disentangled GitHub authentication from workflow triggering mechanics
Disentangled GitHub authentication from workflow triggering mechanics
Two separate things, and the bash script isn't really involved in either login — let me untangle them.

Logging in is for pushing the code, not for running the script. To get the repo onto GitHub in the first place (the git push / gh repo create step), yes, you need to be authenticated to your GitHub account from your machine. That's a one-time setup, via one of:

gh auth login if you use the GitHub CLI (easiest), or
an SSH key tied to your account (for the git@github.com:... remote), or
HTTPS with a Personal Access Token that your git credential helper stores.
The check_secrets.sh file does none of this. It doesn't log in anywhere and doesn't trigger anything on its own — it's just the code that runs inside the GitHub Actions runner once a workflow starts. Running it locally (like I did above) does nothing to GitHub.

What actually triggers the workflow is the push, not the script. The trigger lives in .github/workflows/secrets-demo.yml, in its on: block:

yaml
on:
  workflow_dispatch:        # manual run button
  push:
    branches: [ main ]
So once you've pushed and the repo is on GitHub, any push to main automatically starts a run — you don't log in again for that. GitHub Actions runs on GitHub's own servers; the runner is already authenticated within the repo (it even gets an automatic GITHUB_TOKEN), so there's no separate login for the workflow itself.

The full chain, start to finish:

You authenticate once locally → git push sends the code to GitHub.
That first push to main auto-triggers the workflow — and it'll fail, because you haven't added MY_SECRET/MY_GREETING yet (expected, we covered this).
You add the secret and variable in the repo settings.
Re-run it from the Actions tab using the Run workflow button (that's the workflow_dispatch trigger), or just push another commit.
So: the only login you do is for step 1. After that, pushes trigger runs by themselves, and the script just executes when a run happens. If you'd rather avoid the auto-trigger-on-push entirely and only ever run it by hand, I can strip the push: line so it's workflow_dispatch-only — want me to do that?

for gh I guess I have to install github cli via brew?

20:18

Verified homebrew installation method and authentication workflow
Verified homebrew installation method and authentication workflow
Yep, on macOS that's the simplest route:

bash
brew install gh
Then authenticate (this is the actual login step, done once):

bash
gh auth login
That walks you through an interactive prompt — pick GitHub.com, then HTTPS (or SSH if you prefer), and let it authenticate via the browser. It opens a page, you paste a one-time code, done. After that, gh is logged in and git pushes over HTTPS will use those credentials too, so you won't be prompted again.

Once that's done, the create-and-push from earlier works in one shot from inside the unpacked repo folder:

bash
gh repo create github-actions-secrets-demo --private --source=. --push
(assuming you've already done git init -b main, git add ., git commit first.)

Two honest caveats:

I'm confident brew install gh is the correct, current formula name — it's been stable for a long time. If brew ever complains it can't find it, the official install docs are at https://github.com/cli/cli#installation, which would have the authoritative command.
You don't strictly need gh at all. If you already have an SSH key on your GitHub account, or git already remembers your credentials from past pushes, you can skip the CLI entirely: create an empty repo on github.com in the browser, then use the plain-git git remote add origin … && git push path I gave earlier. gh just saves you the manual "create the empty repo" click and handles auth in one place.
Are you on macOS, and do you already push to GitHub from this machine for your other projects? If you already do, you're probably authenticated and can skip gh setup completely.

gh installed. auth done, now let's go back to creating the repo. Don't make me scroll, give me the files again and the instructions

20:20

Reorganized files and consolidated setup instructions
Reorganized files and consolidated setup instructions
Here's everything in one place.


Presented 4 files
Presented 4 files
Download the tarball (it keeps the .github/workflows/ structure intact), then run these from wherever you downloaded it.

1. Unpack and create the repo on GitHub:

bash
tar -xzf github-actions-secrets-demo.tar.gz
cd github-actions-secrets-demo
git init -b main
git add .
git commit -m "Initial: GitHub Actions secrets demo"
gh repo create github-actions-secrets-demo --private --source=. --push
That first push to main auto-triggers the workflow, and it will fail — expected, because the secret and variable don't exist yet.

2. Add the secret and the variable. In the browser, on the new repo: Settings → Secrets and variables → Actions.

Secrets tab → New repository secret → name MY_SECRET, value super-secret-123
Variables tab → New repository variable → name MY_GREETING, value Hello from a GitHub Actions variable
(Or from the terminal instead of the browser:)

bash
gh secret set MY_SECRET --body "super-secret-123"
gh variable set MY_GREETING --body "Hello from a GitHub Actions variable"
3. Run it. Either push any commit, or go to the Actions tab → Secrets Demo → Run workflow (the workflow_dispatch button). Open the run, expand the "Run the script" step, and read the log — that's where you'll see what's masked vs. what leaks, including the base64 line we were both unsure about.

A couple of things I'm confident in: gh repo create … --source=. --push is the correct one-shot create-and-push form, and gh secret set / gh variable set are the right commands. The one detail I won't assert from memory is whether your gh version defaults gh variable set to repo scope vs. needing an explicit flag — if it complains, gh variable set MY_GREETING --repo <you>/github-actions-secrets-demo --body "..." removes the ambiguity. Tell me what the base64 line shows when you've run it.


Github actions secrets demo.tar
GZ 

Check secrets
SH 

Secrets demo
YML 

Readme
Document · MD 
why did you make it private? it will use credits

20:22

Clarifying GitHub's billing structure for public versus private repositories
Clarifying GitHub's billing structure for public versus private repositories
Fair point — I defaulted to --private out of habit, not for any real reason, and for a throwaway practice repo that's the wrong call. Let me get you accurate numbers rather than guess, since billing figures change.


Searched the web
Searched the web
Claude's response was interrupted.
I don't care about numbers, I just want it public so is free

20:23
Right — public it is, and on a public repo standard runners are free with no minute quota consumed, so zero billing concern.

If you haven't created it yet, just swap --private for --public:

bash
gh repo create github-actions-secrets-demo --public --source=. --push
If you already created it as private, flip it without recreating:

bash
gh repo edit --visibility public
Run that from inside the repo folder. One honest caveat: on recent gh versions that visibility change may refuse to run until you confirm it, and I don't remember the exact flag name from memory — if it complains, it'll tell you the flag to add (it's an "accept consequences"-style confirmation). Either way it won't do anything destructive.

Everything else from before stays the same: add MY_SECRET and MY_GREETING, then run the workflow from the Actions tab.

use of --visibility flag requires --accept-visibility-change-consequences flag
I fixed that

20:24
Good catch — that's exactly the confirmation flag I'd flagged but couldn't name. So gh repo edit --visibility public --accept-visibility-change-consequences did it. Thanks for closing the loop; I'll remember that's the exact flag.

So now you should be all set: public repo, free runs. Add the secret and variable if you haven't, then trigger a run from the Actions tab and read the "Run the script" step.

The line I'm most curious about is #3 — whether the base64 form prints in clear or comes back as ***. Whenever you've got the log, let me know what it shows.

1780338478959_image.png
did the first run fail because secret and variables were not set yet?

20:28

Confirmed failure and pinpointed missing secrets as likely culprit
Confirmed failure and pinpointed missing secrets as likely culprit
Yep — that red ✗ means the run failed, and the timing fits: it ran on your first push to main before you'd added anything, which is exactly the failure we built in on purpose.

To confirm it failed for that reason and not something else, click into the run and expand the "Run the script" step. You should see it stop at the guard line with a message like:

MY_SECRET is not set. Add a repository SECRET named MY_SECRET.
That's the ${MY_SECRET:?...} check exiting on purpose. If instead you see an error in an earlier step (like "Check out the repo"), that'd be a different problem — but the missing secret/variable is by far the most likely cause given the sequence.

So the fix is just what's next on the list: add MY_SECRET and MY_GREETING, then re-run. You don't even need a new commit — go to the run (or the Actions tab → Secrets Demo) and use Re-run jobs / Run workflow. Once both are set, it'll go green and you'll get the masking experiment output, including that base64 line.

1780338563092_image.png
yes, confirmed, and instead what is that warning?

20:29

Investigated Node.js deprecation warning and potential version upgrade
Investigated Node.js deprecation warning and potential version upgrade
That's a deprecation warning, not an error — it didn't cause the failure (the missing secret did). It's GitHub telling you the runtime under actions/checkout@v4 is on its way out. This is exactly the "a newer major may exist" caveat I flagged when I pinned it to v4. Let me verify the current version rather than guess.


Investigated Node deprecation timeline and formulated upgrade recommendation
Investigated Node deprecation timeline and formulated upgrade recommendation
That warning is unrelated to your failure (you already confirmed that was the missing secret) and it's harmless for now — it's a deprecation notice about the JavaScript runtime the action runs on, not your script.

Here's what's behind it. Actions will be forced to run with Node.js 24 by default starting June 2nd, 2026, and Node.js 20 will be removed from the runner on September 16th, 2026. The actions/checkout@v4 you're using still runs on Node 20, so GitHub flags it. Notably, that forced-switch date is tomorrow relative to today — so it's timely, though even then v4 will just be auto-run on Node 24 rather than breaking immediately; the real removal is September. 
GitHub

The fix is a one-line version bump. checkout v5.0.0 updated the action to use Node 24, so change this line in .github/workflows/secrets-demo.yml: 
GitHub

yaml
      - name: Check out the repo
        uses: actions/checkout@v5
That clears the warning. For what it's worth, there's now an even newer major — the release notes reference a v6 — so @v6 is the current latest if you'd rather track the newest; v6 changed how it persists credentials, but for a demo like this either v5 or v6 is fine. I'd go @v5 as the minimal, low-risk bump.

Easiest way to apply it: edit the file directly in the GitHub web UI (open the file → pencil icon → change @v4 to @v5 → commit), which also re-triggers the workflow. Or change it locally and push. Want me to update the workflow file in the repo copy and repackage it, or are you good to make the one-line edit yourself?

One honest note: I verified v5 uses Node 24 and that v6 exists as a newer major, but I didn't dig into v6's exact latest patch number — if you go that route, GitHub's Actions tab will show the precise current tag.








Claude is AI and can make mistakes. Please double-check cited sources.
Check secrets · SH
#!/usr/bin/env bash
set -euo pipefail
 
# These two values are passed in by the workflow's `env:` block, which maps:
#   - a GitHub Actions *Secret*   (sensitive)     -> MY_SECRET
#   - a GitHub Actions *Variable* (non-sensitive) -> MY_GREETING
#
# The `${VAR:?message}` form exits with the given message if the var is
# unset or empty. On your very first run (before you add the secret), this
# will fail on purpose with a clear message — that is expected.
 
: "${MY_SECRET:?MY_SECRET is not set. Add a repository SECRET named MY_SECRET.}"
: "${MY_GREETING:?MY_GREETING is not set. Add a repository VARIABLE named MY_GREETING.}"
 
# POC: echo BOTH values directly to compare how they appear in the logs.
#
# The Variable is non-sensitive and will appear in clear text.
echo "Variable MY_GREETING : ${MY_GREETING}"
 
# The Secret is echoed directly here too, but GitHub auto-masks any
# registered secret value in the log output, so you'll see *** instead
# of the real value. That redaction is the whole point of this demo.
echo "Secret   MY_SECRET   : ${MY_SECRET}"
 
echo "----------------------------------------"
echo "Masking experiments (throwaway value only):"
echo
 
# 1) Wrapped in asterisks. The secret's own characters are still contiguous,
#    so the literal match still finds them. Expected: the middle stays ***.
echo "1. Wrapped     : *${MY_SECRET}*"
 
# 2) Reversed. The literal registered string no longer appears in the output,
#    so there is nothing for the masker to match. Expected: leaks in clear.
echo "2. Reversed    : $(printf '%s' "$MY_SECRET" | rev)"
 
# 3) Base64-encoded. This is the open question — I'm not certain whether
#    GitHub also registers/masks the base64 form of a secret. The run itself
#    is the test. Expected: unknown; watch what actually prints.
echo "3. Base64      : $(printf '%s' "$MY_SECRET" | base64)"
 
echo
echo "Takeaway: any transform that breaks the literal value defeats masking,"
echo "which is why masking is only a backstop, never a reason to print real secrets."
 
