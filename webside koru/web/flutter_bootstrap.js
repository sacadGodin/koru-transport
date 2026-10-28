{{flutter_js}}
{{flutter_build_config}}

// Load this build's own copy of the app code. The ?v= part changes with
// every build, so a browser can never run an old saved copy of it.
const buildVersion = {{flutter_service_worker_version}};
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) build.mainJsPath += '?v=' + buildVersion;
}
_flutter.loader.load();
