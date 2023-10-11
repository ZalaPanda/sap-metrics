# sap-metrics

Duct tape [gorfc](https://github.com/SAP/gorfc#install-gorfc) with Golang [templates](https://pkg.go.dev/text/template) to provide values to 
[Paessler PRTG](https://www.paessler.com/prtg).

> ✋ UPDATE!  
> I think I will create a simple HTTP endpoint like `/default_host/sap/public/ping` (handler: `CL_HTTP_EXT_PING`) and skip dealing with RFC calls & setting the right permissions. PRTG can also retrieve values through HTTP, which is simpler.  
> I really wanted to create something useful in Golang (it was fun to create the template functions). However, sometimes the task is defining the tools, rather than the other way around.

## ICF

Therefore, the **alternative solution** is the following: you need to create the [`ZCL_HTTP_PRTG_METRICS`](zcl_http_prtg_metrics.abap) class in **SAP**, which generates the necessary metrics for **PRTG**.
The necessary steps are:
1. Create the class within with `SE80` (or use [Eclipse](https://www.eclipse.org/downloads/) + [ADT](https://tools.hana.ondemand.com/#abap)).
2. Create a service user (e.g., *PRTG*) using the `SU01` transaction (no role or whatever is needed).
3. Create a service in the `SICF` transaction and assign the *service user* and `ZCL_HTTP_PRTG_METRICS` class as the handler.
4. Done, test it. If you need assistance/help, open an issue or ping me somehow. 🤔

## TODO

- [ ] ~~format error message~~
- [ ] ~~replace *config.yaml* with *config.json*~~
- [ ] ~~config and template filename from parameters~~
- [ ] ~~escape function for texts~~
- [ ] ~~run function modules in parallel~~
- [ ] ~~lot of testing?~~

## NOTES

+ PRTG: [advanced sensors](https://www.paessler.com/manuals/prtg/custom_sensors#advanced_sensors)
+ SAP FM list: `THUSRINFO` `GET_CPU_ALL` `GET_MEM_ALL` `GET_LAN_SINGLE` `GET_DISK_SINGLE` `GET_FSYS_SINGLE` ...
+ SAP CCMS Monitor Sets: `RZ20`

Configure [CGO](https://pkg.go.dev/cmd/cgo) + [sapnwrfc](https://support.sap.com/en/product/connectors/nwrfcsdk.html) for [gorfc](https://github.com/SAP/gorfc#install-gorfc)

1. Download and install [MSYS2](https://www.msys2.org/)
2. Open MSYS terminal and using `pacman`, install `gcc`:  
  `pacman -S mingw-w64-x86_64-binutils mingw-w64-x86_64-crt-git mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-libs mingw-w64-x86_64-gdb mingw-w64-x86_64-headers-git mingw-w64-x86_64-libmangle-git mingw-w64-x86_64-libwinpthread-git mingw-w64-x86_64-make mingw-w64-x86_64-pkg-config mingw-w64-x86_64-tools-git mingw-w64-x86_64-winpthreads-git mingw-w64-x86_64-winstorecompat-git`
3. Download (somehow) `nwrfc750P_10-xxxxxxxx.zip` from SAP
4. Extract the `include` (header files) and the `lib` (binaries) folders to the `...\msys64\mingw64` folder
5. Add the `...\msys64\mingw64\bin` folder to the `$PATH` env variable:
  `setx PATH "%PATH%;...\msys64\mingw64\bin"`

Source: [Golang CGO inside Windows · JJN Tech Adventures](https://jjn.one/posts/golang-gco-windows/)