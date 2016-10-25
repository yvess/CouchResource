/*
 * Jakefile
 *
 */


var ENV = require("system").env,
    FILE = require("file"),
    OS = require("os"),
    JAKE = require("jake"),
    task = JAKE.task,
    CLEAN = require("jake/clean").CLEAN,
    FileList = JAKE.FileList,
    framework = require("cappuccino/jake").framework,
    configuration = ENV["CONFIGURATION"] || "Release";

framework ("CouchResource", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "CouchResource.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("CouchResource");
    task.setVersion("1.0");
    task.setEmail("y@yas.ch");
    task.setSummary("CouchResource");
    task.setSources(new FileList("*.j", "CouchResource/*.j"));
    task.setResources(new FileList("Resources/*"));
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task("build", ["CouchResource"]);

task("debug", function()
{
    ENV["CONFIGURATION"] = "Debug"
    JAKE.subjake(["."], "build", ENV);
});

task("release", function()
{
    ENV["CONFIGURATION"] = "Release"
    JAKE.subjake(["."], "build", ENV);
});

task ("default", ["release"]);
task ("all", ["release", "debug"]);
