-- @description Transpose notes down to next visible note in Custom Note Order mode
-- @author Luiza177
-- @about Transpose MIDI notes down to next visible note in Custom Note Order view (or just transpose notes down by a semitone)
-- @noindex

package.path = package.path..';'..debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;"
require('luiza177_Custom note order view transpose')

TransposeCustom(-1)
