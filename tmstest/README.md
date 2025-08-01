# Setting up the environment

1. tmstest runs on PowerShell. If in linux, you need to install PowerShell for linux.
2. For debugging, we recommend VSCode. Install the powershell extension.
3. Setup the paths. You will have to do this from the **terminal** and from the **VSCode terminal**, since they load different user profiles.

Go to the terminal you want to use (VSCode terminal or normal terminal) and type:

```shell
code $PROFILE
```
This will open your profile. Add the lines (adapting the paths for the machine)

```shell
set-alias tms E:\tms\smartsetup\tms\bin\Win64\Debug\tms.exe

$tmsTestRootDir = "E:\tms\tms-smartsetup\tmstest"
set-alias test.setup "$tmsTestRootDir\util\util.setup.ps1"
set-alias tmstest "$tmsTestRootDir\tmstest.ps1"

$env:TMSTEST_CODE="<reg-code>"
$env:TMSTEST_EMAIL="<reg-email>"
```

Once you have this done, **restart the terminal** (or VSCode). Now you should be able to type `$tmsTestRootDir` and have see the value.

> ![Important]
> If you save the reg/code in the profile, it will be stored there. You might prefer to set the variable in other manually.

# Running the tests

## Running from the console.

### Running all tests

```
tmstest
```
This will run all tests, and show which failed and which didn't.
A file *output.log* will be generated inside the `tmp-run\{test_folder}` for every test, with the output of the corresponding test.
Those folders might also have log files from smartsetup, if they run some smartsetup command.

### Running one test or a specific group of tests

```
tmstest build
```
this will run all tests that have `build` inside their name. We search for `test.*{parameter}*.tms` so in this case, this will run all tests matching `test.*build*.ps1`.

> [!NOTE]
> Don't run the tests directly, by executing them in the command line. They will refuse to run, because they need to be run outside the `tests` folder. Otherwise they would create their temporary files in the wrong place. To run them manually, call `tmstest name-of-the-test` instead. `tmstest will basically copy the folder to tmp-run, and run it there.

### Slipping slow tests
```
tmstest -skip-slow
tmstest build -skip-slow
```
Will skip all slow tests.

### Debugging from the console

Sometimes, VSCode might not work or be a viable solution for debugging. You can use:
```shell
 Set-PSDebug -Trace 1 
```
To get a lot of what is happening in the console. Set it to 2 to be more verbose, and to 0 to reset to normal use.

## Running from Visual Studio Code

You can also use VSCode to debug the tests. To do so, you can open the workspace at the root: `tmstest.code-workspace`.

> [!NOTE]
> As you can't run the tests directly individually (you need to call them from `tmstest.ps1`), the workspace is configured to always run `tmstest.ps1`, no matter the active page. If you are in a particular test, VSCode will launch `tmstest.ps1 <filename_with_the_test.ps1>` instead of launching `filename_with_the_test.ps1` directly. You can change this in the folder `\.vscode\launch.json`

Currently `launch.json` is:
```json
 {
       ...
      "script": "${workspaceFolder}/tmstest.ps1 ${file}"
 }
```
So it will always launch tmstest.ps1, passing the active file as a parameter.
You can then run this normally: F5 starts the run, F10 steps over, F11 steps inside, etc.

> [!IMPORTANT]
> There are many "Run" commands in VS. F5 will work. Also pressing the triangle in "SmartSetup Tests" in the "Run and Debug panel at the right will work. But there is a small triangle at the top left that won't call tmstest.ps1 and run the test directly. That will likely fail if isn't at the right place. If it fails, just use F5 instead to run it.

# Creating the tests

The test is just a script that does commands, and if it returns an ErrorCode of 0, it is successful. If not, it failed. You can write to the screen during the test, but it won't show in the main `tmstest.ps1` app, unless you are running a single test. Anyway, the output will always be available in **output.log** in the `tmp-run\<test_name>` folder.

## Guidelines for creating tests

  * Tests must all start with the name **`test.`** 

  * Tests that take long to execute (like `tms install *`) should start with the name **`test.slow.`**. We can exclude those tests from running by calling `tmstest -skip-slow`.

  * Tests must not depend on other tests. A test must be able to run on its own, and not depend on the result of any other test. In the future, we might run the tests in parallel, so they can't assume any other test already completed.

  * Tests will run in a temp folder. The current folder will be the temp folder when called, so it must work that way. It can't assume the script is at the root of the test.

  * Tests should be inside of a folder with a similar name as the script. The folder name isn't important, but to make it simpler to edit it, they should have a similar name, but shorter. For example the test `test.build.framework-defines.ps1` can be inside a folder named `framework-defines`.  
  
  * Tests might be relocated in the folder hierarchy. We might move them to subfolders if they grow too much or reorganize the folder structure, and they should keep working. They shouldn't rely in being in any specific folder.

  * Do not specify delphi versions or platforms in the tmsbuild.yaml in the tests. We will manage this from a centralized location. 

  * When building products, either `skip register` or install to some `alternate registry key`. IF installing to an alternate registry key, make sure to uninstall everything after installing.

  * If the test references a bug report, it should have a comment linking to it.

  * **The script must always start by calling `. test.setup` on the first line**. This will setup the environment, like for example making PowerShell stop on errors. **The `.` at the start of the line is important**, it means that the script will be sourced, instead of running on its own environment.
  
  * To **terminate** the script with an error, you can either call:
      * `Write-Error`: Will write the error in red, but **also stop the script with an error code**. You can specify a specific error code as parameter of `Write-Error` if you want
      * **exit(-1)** will exit with an error code of -1. 

> [!NOTE]
> The Write-Error behavior can be confusing. I would expect it to just write the error, not also terminate the script. But it does both. Use it with care. 

## Utilities for writing tests