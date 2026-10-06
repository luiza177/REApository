#define REAPERAPI_IMPLEMENT
#include "reaper_plugin.h"
#include "reaper_plugin_functions.h"

// static int g_cmdId = 0;
//
// // INFO: register in the action list, needs to be static
// static custom_action_register_t g_action = {
//     0,                  // section 0 = Main
//     "HELLO_ACTION",     // unique command name (stable ID)
//     "Hello: say hello", // name shown in the Actions list
//     nullptr,
// };
//
// // INFO: Action callback
// static bool OnAction(KbdSectionInfo *, int command, int, int, int, HWND) {
//   if (command != g_cmdId)
//     return false; // not ours, let others handle it
//   ShowConsoleMsg("Action triggered!\n");
//   return true; // handled
// }
// ------ Alternatively, to set up multiple actions:

// Q: should this be a proper class with get/set methods?
struct Action {
  custom_action_register_t reg;
  void (*run)();
  int cmdId;
};

static void SayHello() { ShowConsoleMsg("Hello!\n"); }
static void SayBye() { ShowConsoleMsg("Bye!\n"); }

static Action g_actions[] = {
    {{0, "HELLOEXT_HELLO", "Hello: say hello", nullptr}, SayHello, 0},
    {{0, "HELLOEXT_BYE", "Hello: say bye", nullptr}, SayBye, 0},
};

static bool OnAction(KbdSectionInfo *, int command, int, int, int, HWND) {
  for (auto &a : g_actions) {
    if (a.cmdId != 0 && command == a.cmdId) {
      a.run();
      return true; // handled
    }
  }
  return false; // not ours
}

//  INFO: Main plugin function
//  ===================================================
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
    return 0; // HINT: All REAPER API is already setup, eg. ShowConsoleMsg /
              // GetTrack / etc

  // -------------------------- ABOVE: essentially boilerplate

  // show message on reaper startup / ext load
  // ShowConsoleMsg("Hello from my C++ extension!\n");

  // ----------- set up single action:

  // g_cmdId = plugin_register("custom_action",
  //                           &g_action); // INFO: registers in action list
  // plugin_register(
  //     "hookcommand2",
  //     (void *)OnAction); // INFO: gets called whenever ANY action gets called

  // ----------- set up multi actions:
  for (auto &a : g_actions)
    a.cmdId = plugin_register("custom_action", &a.reg);

  plugin_register("hookcommand2",
                  (void *)OnAction); // HINT: only one per extension

  return 1; // 1 = loaded successfully
}
