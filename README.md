# eg2xsd #

An XSLT transformation that compiles an 
[Examplotron](http://www.examplotron.org) schema into an XML Schema
(XSD) file.

Subject to differences in expressibility between XML Schema and 
RelaxNG, this transform attempts to faithfully implement the 
Examplotron schema language, as of 
[v0.8](http://examplotron.org/0/8/) (21 August 2013), and then
add a few extensions not present in the canonical Examplotron.

For compatibility, it reads the Examplotron v0.* namespace: 
`xmlns:eg="http://examplotron.org/0/"`

Extensions use the extension namespace:
`xmlns:egx="http://accuity.com/egx/0/"`

For most input, this transform will produce a XSD 1.0 compliant
schema. Known exceptions are: 

1. If assertions are made with eg:assert
2. If elements of unbounded occurrence appear in elements with
 eg:interleave'd or mixed content models

See CHANGES.md for more details

## Implementation Changes ##
Using XSD rather than RelaxNG as the output format means differences
in what can be expressed meaningfully. 

Extensions include:

* Choice content model
* Import/Include functionality
* Pattern constraints (regex)
* Enum constraints

For all changes and extensions, see CHANGES.md

## Testing ##

test/eg2xsd.xspec describes test scenarios that can be run using the
[XSpec](https://github.com/expath/xspec) testing framework.

`xspec.sh test/eg2xsd.xspec` on Mac/Linux, or 
`xspec.bat test\eg2xsd.xspec` on Windows

## To Do ##

* Allow import of type definitions as well as elements
* Allow import of attributes
* @egx:maxLength