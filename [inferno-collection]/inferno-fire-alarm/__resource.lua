-- Inferno Collection Fire Alarm Version 4.5 BETA
--
-- Copyright (c) 2019, Christopher M, Inferno Collection. All rights reserved.
--
-- This project is licensed under the following:
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to use, copy, modify, and merge the software, under the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. THE SOFTWARE MAY NOT BE SOLD.
--

-- Manifest Version
resource_manifest_version "77731fab-63ca-442c-a67b-abc70f28dfa5"

-- Client Script
client_script "client.lua"

-- Server Scripts
server_script "server.lua"

-- NUI Page
ui_page "html/index.html"

-- Required Files
files {
    "call-points.json",
    "control-panels.json",
    "html/index.html",
    "html/sounds/all_clear.ogg",
    "html/sounds/test.ogg",
    "html/sounds/alarm.mp3",
    "html/sounds/panelsounder.ogg",
    "html/imgs/ack1.png",
    "html/imgs/fire.png",
    "html/imgs/gack.png",
    "html/imgs/menu1.png",
    "html/imgs/menu2.png",
    "html/imgs/menu3.png",
    "html/imgs/menu4.png",
    "html/imgs/res.png",
    "html/imgs/resc.png",
    "html/imgs/sil.png",
    "html/imgs/sysnormal.png",
    "html/imgs/locked.png",
    "html/imgs/1.png",
    "html/imgs/2.png",
    "html/imgs/3.png",
    "html/imgs/4.png"
}