#SingleInstance Force
#Persistent
#NoEnv
#MaxThreadsPerHotkey 1
#MaxHotkeysPerInterval 999
#MaxThreads 15
#InputLevel 1
#KeyHistory 0
#warn all, OutputDebug
SetBatchLines -1
AutoTrim Off
ListLines Off
SendMode Input
SetWorkingDir % A_ScriptDir
DetectHiddenWindows On

SetKeyDelay, 50, 50
CoordMode Pixel, Screen
CoordMode Mouse, Screen
SetMouseDelay 50
SetDefaultMouseSpeed 0
SetTitleMatchMode 2