# Implementation Differences #
Using XSD rather than RelaxNG as the output format means differences
in what can be expressed meaningfully.

This means that certain things are not possible, certain things are
possible but hard enough to implement that they have been omitted,
and certain extensions that were useful and easy to implement have
been added.


## Behaviour Changes ##

### Extension via XSD embedding rather than RNG embedding ###

Whereas the original Examplotron compile.xsl allows Examplotron 
documents to contain rng: namespaced elements, and copies them into
the target document, this compiler does the same thing with xsd: 
namespaced elements.

### Assertions create xs:assert nodes rather than Schematron ###
XSD 1.1 supports assertions directly, so this capability is used, 
rather than using Schematron. That does mean any Examplotron document
that uses eg:assert will compile to an XSD 1.1 schema.

### Type libraries ###
External type libraries are not supported.

DTD types are interpreted as XSD native types. Whether DTD rules are 
strictly applied will depend on validator implementation.

### Multiple namespaces ###
XSD does not support more than one target namespace for a single
schema. Rather than try to parse each namespace out of the 
Examplotron document and into a separate xsd file, eg2xsd requires
that each namespace be defined by a separate Examplotron document.

However, elements from one namespace can be referenced in another
using a new eg:from attribute described below.

Some related functionality may not work correctly, for example, 
referencing foreign namespaces in assertions or datatypes.


### Mixed content ###
XSD's handling of mixed content is different to that of RNG. In 
particular:

\1. Mixed content may be 'sequential' as well as interleaved. This
transform assumes mixed content is intended to be interleaved, as in
RelaxNG schemas.

```xml
<foo xmlns:eg="http://examplotron.org/0/">
	Content will be inferred to be <b>mixed</b>!
</foo>
```

```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
  elementFormDefault="qualified">
  <xs:element name="foo">
    <xs:complexType mixed="true">
      <xs:all>
        <xs:element name="b" type="xs:string"/>
      </xs:all>
    </xs:complexType>
  </xs:element>
</xs:schema>
```
 
\2. Nodes of 1-or-more cardinality cannot appear in interleaved 
content, including mixed interleaved content, in XSD 1.0. 
eg2xsd will still create them if requested, but the resulting schema
will be XSD 1.1.

```xml
<foo xmlns:eg="http://examplotron.org/0/">
  Valid only in <b eg:occurs="+">XSD 1.1</b>.
</foo>
```

```xml
<foo xmlns:eg="http://examplotron.org/0/">
  Valid <b>only</b> in <b>XSD 1.1</b>.
</foo>
```

```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
  elementFormDefault="qualified">
  <xs:element name="foo">
    <xs:complexType mixed="true">
      <xs:all>
        <xs:element name="b" maxOccurs="unbounded" type="xs:string"/>
      </xs:all>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

\3. XSD does not support the ordering of text nodes within mixed 
content, so the eg:content="eg:group" only imposes an ordering on the
child elements within such a group. If an ordering is imposed, then 

```xml
<foo xmlns:eg="http://examplotron.org/0/" eg:content="eg:group">
  Mixed <i>content</i> with <b>sequential</b> elements.</foo>
</root>
```

```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
  elementFormDefault="qualified">
  <xs:element name="foo">
    <xs:complexType mixed="true">
      <xs:sequence>
        <xs:element name="i" type="xs:string"/>
        <xs:element name="b" type="xs:string"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
```


## Additional Functionality ##

Additional features are defined in the egx namespace
`xmlns:egx="http://accuity.com/egx/0/"`

### Choice Model ###
To augment the existing content model options, 'egx:choice' is 
defined. This straightforwardly converts to an xs:choice content
model.

```xml
<root xmlns:eg="http://examplotron.org/0/" eg:content="egx:choice">
  <foo>123</foo>
  <bar>2012-01-01</bar>
  <baz>something</baz>
</root>
```

```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  elementFormDefault="qualified">
  <xs:element name="root">
    <xs:complexType>
      <xs:choice>
        <xs:element name="foo" type="xs:integer"/>
        <xs:element name="bar" type="xs:date"/>
        <xs:element name="baz" type="xs:string"/>
      </xs:choice>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

### Imports and Includes ###

A new attribute @egx:from is defined to allow inclusion of schema 
elements from one file into another. 

This is required to replace the RNG feature of permitting multiple
target namespaces to be used in the same schema definition, but it 
also allows a more modular approach, so that each schema file can be
built separately, and parts shared between them. 

If the element with the eg:from attribute is in the same namespace as
the root element, an 'xs:include' is created. If it comes from a 
different namespace, then an 'xs:import' is created.

This example from the original Examplotron documentation converts 
to a single RelaxNG file with both namespaces present.

```xml
<foo xmlns:eg="http://examplotron.org/0/" 
    xmlns:bar="http://examplotron.org/otherns/">
  <bar:bar eg:occurs="+">Hello world</bar:bar>
</foo>
``` 

In eg2xsd, a similar result can be achived with:

foo.xml
```xml
<foo xmlns:eg="http://examplotron.org/0/" 
    xmlns:egx="http://accuity.com/egx/0/"
    xmlns:bar="http://examplotron.org/otherns/">
  <bar:bar eg:occurs="+" egx:from="bar.xsd"/>
</foo>
```

bar.xml
```xml
<bar xmlns="http://examplotron.org/otherns/">
  Hello World
</bar>
```

After transforming both, you will have:

foo.xsd
```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  elementFormDefault="qualified">
  <xs:import namespace="http://examplotron.org/otherns/" 
    schemaLocation="bar.xsd"/>
  <xs:element name="foo">
    <xs:complexType>
      <xs:sequence>
        <xs:element xmlns:bar="http://examplotron.org/otherns/" 
          ref="bar:bar" maxOccurs="unbounded"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

bar.xsd
```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" 
   elementFormDefault="qualified" 
   targetNamespace="http://examplotron.org/otherns/">
  <xs:element name="bar" type="xs:string"/>
</xs:schema>
```



### Documentation ###
To give more control over documentation annotations within the XSD,
and with apologies to Eric's iconic 80%, a new egx:docs element is 
defined. It can be used within any element (including eg:attribute 
elements) to add an annotation to the XSD. It is transparent to 
the content type detection logic.

```xml
<date xmlns:egx="http://accuity.com/egx/0/">
  <egx:docs>It's a date.</eg:docs>
  2016-01-01
</date>
```

```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" 
   elementFormDefault="qualified">
  <xs:element name="date" type="xs:date">
    <xs:annotation>
      <xs:documentation>It's a date.</xs:documentation>
    </xs:annotation>
  </xs:element>
</xs:schema>
```

### Enum Constraints ###
Allows authors to define a schema component which must take one of
the enumerated values. Write the permitted values, each bracketed by
pipe characters. Whitespace is trimmed, to allow line breaks to be
added for readability.

Unless an xsd: datatype is specified using the eg:content syntax, 
the first element in the list is type-checked to define the datatype
for the element or attribute in question.

This is not supported in mixed content text sections.

```xml
<elementWithEnum xmlns:eg="http://examplotron.org/0/">|1|2|3|</elementWithEnum>
```

```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    elementFormDefault="qualified">
  <xs:element name="elementWithEnum">
    <xs:simpleType>
      <xs:restriction base="xs:integer">
        <xs:enumeration value="1"/>
        <xs:enumeration value="2"/>
        <xs:enumeration value="3"/>
      </xs:restriction>
    </xs:simpleType>
  </xs:element>
</xs:schema>
```

### Pattern Constraints ###
Allows authors to define schema components with XSD pattern
constraints using the usual regular expression syntax.

This is not supported in mixed content text sections.

```xml
<elementWithPattern xmlns:eg="http://examplotron.org/0/">/z[aeiou]+/</elementWithPattern>
```

```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	elementFormDefault="qualified">
	<xs:element name="elementWithPattern">
		<xs:simpleType>
			<xs:restriction base="xs:string">
				<xs:pattern value="z[aeiou]+"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
</xs:schema>
```


## Missing Behaviours ##

### Example content ###
Unlike the original, eg2xsd.xsl is not reversible, as the 
Examplotron fragments are not preserved within the XSD. 

### External type libraries ###
Not sure how to support this.

### Foreign namespace on root eg:attribute elements ###
Hopefully a rare use case.

