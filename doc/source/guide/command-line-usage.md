---

uid: SmartSetup.CommandLineUsage

---

# Command-line usage

TMS Smart Setup is folder-based. Once you have the folder initialized, you can run the command-line and Smart Setup will create files and subfolder inside it..

The command-line is self-explanatory, just run `tms` to list all available commands, or `tms help <command>` for more detailed information about a specific command.

## Setting up credentials

Once in the folder, run `tms credentials` to initialize the folder and input your credentials:

```shell
tms credentials
```

## Installing products

Then use `install` command to download new products from the remote repository to your local machine. 

```shell
tms install tms.biz.aurelius
```

It's worth noting that the above command will download and install TMS Aurelius and also all its dependencies (in this case, TMS BIZ Core Library ).

To find out what are the ids of the products you have available to install, you can run `list-remote` command:

```shell
tms list-remote
```

You can also specify multiple products to install, separated either by comma or spaces. Masks can be used to install all products that match the mask. For example, the following command installs all BIZ products and TMS Flexcel for VCL:

```yaml
tms install tms.biz.* tms.flexcel.vcl
```

## Updating products

From time to time, you can run `update` command to download newest versions of the products, if available:

```shell
tms update
```

The above command will check in the remote repository for new versions of all products you have installed. If there are new versions, it will download, update and rebuild them, all automatically.

## Rebuilding

When installing or updating products, TMS Smart Setup only rebuilds what has been modified. This makes the installation and update processes very fast. 

But there are times that the build process might fail, for any reason (Delphi misconfiguration, antivirus in action, bugs, etc.). In this case, you will have your products downloaded but not properly built and registered in the IDE. 

To force a new rebuild to fix these issues, just call the `build` command:

```shell
tms build
```

This command will just try to rebuild what has been modified or failed, and quickly fix that. In case things are really not working, you can ask for a full rebuild, which will rebuild and re-register all your products:

```shell
tms build -full
```

You can also use the `build` command if you updated the source code of TMS products yourself. After modifying the source code, call `build` command to update the installation properly.

## Uninstalling a product

Uninstalling a product is as simple and similar as installing. Just call `uninstall` passing the products to be uninstalled. It also accepts masks and comma-separated ids:

```shell
tms uninstall tms.biz.aurelius
tms uninstall tms.biz.*,tms.flexcel.vcl
```

Note that `uninstall` command **does not** uninstall dependencies. Thus, if you ask to uninstall `tms.biz.aurelius` only, then `tms.biz.bcl`, which is an TMS Aurelius dependency, will remain installed. To uninstall a product and all its dependencies, use the `-cascade` option:

```
tms uninstall tms.biz.aurelius -cascade
```

It might be possible that you try to uninstall a product that another installed product depends on. For example, if you try to uninstall TMS BCL but not TMS Aurelius, which depends on BCL In this case, `uninstall` will fail. You can bypass this check by adding the `-force` parameter. But we don't recommend it, because you will end up with bad-installed products. Only use it if you really know what you are doing.

## Custom configuration

TMS Smart Setup works smoothly out of the box. It automatically detects all your installed Delphi IDEs and platforms, in summary, your current system setup, and installs everything the best way possible in your environment.

But if you want more control over its behavior, you can fully customize its behavior by using a YAML config file.

You can ask the tool to create a preconfigured YAML configuration file by running the `config` command:

```shell
tms config
```

This will create a YAML file named `tms.config.yaml` in your root folder, and launch your default YAML editor to edit its content.

The default YAML config file contains all the available configuration options you can modify, and each of them is fully documented. Just read the file to learn about it and modify the options as you wish. For more information, see the [configuration guide](xref:SmartSetup.Configuration).

## Check what is installed

You can use command `tms list` to check all products you have installed locally:

```shell
C:\tms>tms list
tms.biz.aurelius (5.16.0.1)
tms.biz.bcl (1.38.0.1)
tms.biz.sparkle (3.25.0.1)
tms.biz.xdata (5.13.0.1)
```

Using the `-detailed` parameter displays the exact IDE and platforms for which each product is installed:

```shell
C:\tms>tms list -detailed
tms.biz.aurelius (5.16.0.1)
- delphi11
  - win32intel
  - win64intel
  - linux64

tms.biz.bcl (1.38.0.1)
- delphi11
  - win32intel
  - win64intel
  - linux64

tms.biz.sparkle (3.25.0.1)
- delphi11
  - win32intel
  - win64intel
  - linux64

tms.biz.xdata (5.13.0.1)
- delphi11
  - win32intel
  - win64intel
  - linux64
```

## Self-updating

`tms.exe` can update itself. It will regularly check for new versions, and if available, it will warn you about it.

At any time, specially if you get such warning, you can update `tms.exe` to a newer version by executing `self-update`:

```shell
tms self-update
```

We recommend to not ignore the warnings about a new version, and always keep the tool updated to the latest version.

## Automation
A common use-case for the tms executable is to call it from your own scripts, or even from a GUI. That's how tmsgui works under the hood. For those cases, the following commands and options might come up handy:


### `-json` parameter, to get the results in a json object instead of plain text. 

For example:
```shell
tms list -json
tms list-remote -json
tms credentials -print -json
tms info -json
tms server-list -json
```

### `-p` command, to pass a configuration to tms 

Our configuration is normally done in `tms.config.yaml`. This allows your all your settings to be in a single, version-controled file. 
But sometimes, you might want to call tms with some specific configuration, but not alter the existing `tms.config.yaml`
On those cases, you can use the "-p" parameter to override any property in `tms.config.yaml`
The rules are: 
 1. Take a look at the path for the property in tms.config.yaml. Say we want to change the skip-register setting: it is under `configuration for all products`, then `options`, then `skip register`
 2. Replace the spaces by "-" signs. Note: this step is optional, you can still write the names with spaces, but you will need to quote them so the command line accepts them.
 3. Join the sections with ":"
 4. If the variable you want to set is an array (like for example the delphi versions), you set them by putting them between brackets and separating them with commas. For example: [delphi11,delphi12].

 Some examples (the first and the second are similar, but the second omits step 2 above)

```shell
tms build -p:configuration-for-all-products:options:skip-register=true
tms build -p:"configuration for all-products:options:skip register=true"
tms build -p:configuration-for-all-products:platforms=[win32intel,win64intel] -p:configuration-for-all-products:delphi-versions=[delphi12]
```

{{#Tip}}
As this property is designed to be used mainly when automating, we didn't care to make it less verbose. As it is, it might be difficult to get it right.
To experiment, you can use `tms config-read` and `tms config-write` instead of `tms build -p` as it is faster to iterate. `tms config-read` uses the same syntax, so when you get it right, you can apply the same syntax to `-p`
{{/Tip}}

### `tms config-read` and `tms config-write` to read and change tms.config.yaml
Those two commands allow you to read or update a setting from `tms.config.yaml`. Different from the `-p` parameter, `tms config-write` will modify the actual file. This can be useful for example when doing a gui: You can use `tms config-read` to read a value from the config file and show it to the user. When the user modifies it, you can use `tms config-write` to write it back.

The syntax to specify the setting to read or write is the same as the one in the `-p` parameter above. In fact, `config-write`, when called alone, just reads your settings and writes them back reformatting the config file. You need to use the `-p` parameter to alter that configuration, so what is written is different from the existing settings.

Examples:
```shell
tms config-read configuration-for-all-products:delphi-versions
tms config-write tms config-write -p:configuration-for-tms.flexcel.vcl:platforms=[] -p:tms-smart-setup-options:prevent-sleep=false -p:tms-smart-setup-options:git:git-location="" -p:configuration-for-all-products:platforms=[]
```

{{#Important}}
`tms config-write` will reformat and remove all manually entered comments in tms.config.yaml. See [configuration](xref:SmartSetup.Configuration)
{{/Important}}

## Fixing problems
To open a browser showing a complete log of the last command, you can type:

```shell
tms log-view
```
If you are still having issues that you can't solve, you might try

```shell
tms doctor
```
You can find more information about [tms doctor here](xref:SmartSetup.Doctor)
