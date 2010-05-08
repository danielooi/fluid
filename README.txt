Site-Specific Browser Creator for Mac OS X Leopard or later. Apache 2 License.

Requires the Fluidium project which provides the SSB: http://github.com/itod/fluidium

To build, checkout both the fluid and fluidium projects in the same directory, then build the "Fluid" target in the fluid/Fluid Xcode project. This target has a dependency on the "Fluidium" target in the fluidium/Fluidium Xcode project, which will also be built.

