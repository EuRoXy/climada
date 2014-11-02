climada
=======

climada core module (MATLAB), https://github.com/davidnbresch/climada

This contains the full climada distribution. To get it all in one, click on the "Download ZIP" button on the lower right hand side of github, or just clone this repository. Works both if main folder renamed to 'climada' or left as 'climada-root', just source startup.m in MATLAB and test using climada_demo.

See folder docs/climada_manual.pdf to get started

Once you’ve installed core climada, you might expand its functionality by adding additional modules (see repositories on GitHub under https://github.com/davidnbresch). In order to grant core climada access to additional modules, create a folder ‘modules’ in the core climada folder and copy/move any additional modules into climada/modules. You can shorten the folder names (i.e. get rid of 'climada_modules' and '-master' in the module folder names, e.g. shorten 'climada_modules_tc_surge-master' to 'tc_surge' - climada parses the content of the modules dir and treats what's in there). You might also create a folder ‘parallel’ to climada (i.e. in the same folder as the core climada folder) and name it climada_modules to store additional modules, but this special setup is for developer use mainly). Once you've cloned repositories to your desktop, please consider the climada command climada_git_pull_repositories to update your repositories from within climada (saves you keeping track of all repositories and updating each separately).

copyright (c) 2014, David N. Bresch, david.bresch@gmail.com
all rights reserved.
