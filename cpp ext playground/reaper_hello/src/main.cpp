#define REAPERAPI_IMPLEMENT
#include "reaper_plugin.h"
#include "reaper_plugin_functions.h"

extern "C" REAPER_PLUGIN_DLL_EXPORT int
ReaperPluginEntry(REAPER_PLUGIN_HINSTANCE hInstance,
                  reaper_plugin_info_t *rec) {
  if (!rec) {
    // REAPER is unloading us: clean up here later
    return 0;
  }

  if (rec->caller_version != REAPER_PLUGIN_VERSION)
    return 0;

  // Resolves every REAPER API function pointer (ShowConsoleMsg, etc.)
  if (REAPERAPI_LoadAPI(rec->GetFunc) != 0)
    return 0;

  ShowConsoleMsg("Hello from my C++ extension!\n");
  return 1; // 1 = loaded successfully
}
