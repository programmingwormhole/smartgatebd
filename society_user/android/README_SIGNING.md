Local keystore generation and placement

This project expects a keystore file at `android/app/smartgatebd.jks` and a `key.properties` file at `android/key.properties` with the following keys:

```
storePassword=...
keyPassword=...
keyAlias=...
storeFile=app/smartgatebd.jks
```

To generate the keystore locally (requires Java), run this command in your shell from the project root:

```bash
keytool -genkeypair -v -keystore android/app/smartgatebd.jks -alias smartgatebd -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass <STORE_PASSWORD> -keypass <KEY_PASSWORD> \
  -dname "CN=SmartGateBD, OU=SmartGateBD, O=SmartGateBD, L=Dhaka, S=Dhaka, C=BD"
```

After generation confirm the file exists:

```bash
ls -l android/app/smartgatebd.jks
```

If you prefer, you can generate the keystore on another machine and copy `smartgatebd.jks` into `android/app/`.

Security note: `key.properties` contains sensitive passwords. Do not commit it to a public repository. Add `android/key.properties` to `.gitignore` if you plan to commit the repo.
