{
  lib,
  fetchurl,
  jq,
  writeTextFile,
  dsh,
}:
dsh.helpers.buildBundle (_: {
  pname = "dsh-agy-safe";
  version = "0.1.8";
  src = fetchurl {
    url = "https://registry.npmjs.org/dsh-agy-safe/-/dsh-agy-safe-0.1.8.tgz";
    hash = "sha512-idpTBewlL8eNutk78JouN3iNcel+GY0KFTCDd/nxGlJIYSY8gOAmBAkcCBiFHAHjlEMaf2Dvk16HuN++EyVgmQ==";
  };
  nativeBuildInputs = [jq];
  linkKernelNodeModules = dsh.dsh-kernel;
  postPatch = ''
    jq 'del(.scripts, .dependencies, .devDependencies, .peerDependencies, .peerDependenciesMeta)' \
      package.json > package.json.tmp
    mv package.json.tmp package.json
    substituteInPlace lib/index.js \
      --replace-fail "export const inject = ['llm', 'webServer', 'settings'];" "export const inject = ['llm'];"
  '';
  npmConfigHook = writeTextFile {
    name = "noop-npm-config-hook";
    destination = "/nix-support/setup-hook";
    text = "";
  };
  npmDeps = null;
  dontBuild = true;
  dontNpmBuild = true;
  dontNpmInstall = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/node_modules/dsh-agy-safe"
    cp -r * "$out/lib/node_modules/dsh-agy-safe/"
    runHook postInstall
  '';
  meta = {
    description = "Use a logged-in Antigravity CLI (agy) headless session as the chat and subagent model provider";
    license = lib.licenses.mit;
  };
})
