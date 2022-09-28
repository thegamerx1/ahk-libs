#SingleInstance force
#Persistent
#NoEnv
#MaxThreadsPerHotkey 1
#MaxHotkeysPerInterval 200
#MaxThreads 6
#InputLevel 1
#KeyHistory 0
#warn all, OutputDebug
SetBatchLines 50
AutoTrim Off
ListLines Off
SendMode Input
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows On
global A_DebuggerName

SetKeyDelay, 50, 50
CoordMode Pixel, Screen
CoordMode Mouse, Screen
SetMouseDelay 50
SetDefaultMouseSpeed 0
SetTitleMatchMode 2