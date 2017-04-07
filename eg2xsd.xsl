<?xml version="1.0" encoding="UTF-8"?>
<!--
eg2xsd

This compiler is a XSLT transformation that compiles an
Examplotron schema into an XML Schema (XSD) file.

Subject to differences in expressibility between XML Schema and
RelaxNG, this transform attempts to faithfully implement the
Examplotron schema language, as of
   v0.8 (21 August 2013)

and adds a few extensions not present in the canonical Examplotron

For compatibility, it uses the Examplotron v0.* namespace:
   http://examplotron.org/0/

Extensions use the extension namespace:
   http://accuity.com/egx/0/

-->
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:eg="http://examplotron.org/0/"
	xmlns:egx="http://accuity.com/egx/0/"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"

	exclude-result-prefixes = "eg egx"
	>
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:strip-space elements="*"/>
	<xsl:variable name="eg-uri" select="'http://examplotron.org/0/'"/>
	<xsl:variable name="egx-uri" select="'http://accuity.com/egx/0/'"/>
	<xsl:variable name="Header" select="'0.8'"/>

	<xsl:template match="/">
		<xs:schema elementFormDefault="qualified">
			<xsl:variable name="rootns" select="namespace-uri(descendant::*[not(self::eg:*) and not(self::egx:*) and not(self::xs:*)])"/>
			<xsl:if test="$rootns != ''">
				<xsl:attribute name="targetNamespace">
					<xsl:value-of select="$rootns"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="//*[@egx:from]" mode="eg:imports">
				<xsl:with-param name="rootns" select="$rootns"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="node()"/>
			<xsl:apply-templates select="//*[@eg:define]" mode="eg:def">
				<xsl:sort select="@eg:define"/>
			</xsl:apply-templates>
		</xs:schema>
	</xsl:template>

	<xsl:template match="*" mode="eg:imports">
		<xsl:param name="rootns"/>
		<xsl:choose>
			<xsl:when test="namespace-uri(.) != $rootns">
				<xs:import>
					<xsl:attribute name="namespace">
						<xsl:value-of select="namespace-uri(.)"/>
					</xsl:attribute>
					<xsl:attribute name="schemaLocation">
						<xsl:value-of select="@egx:from"/>
					</xsl:attribute>
				</xs:import>
			</xsl:when>
			<xsl:otherwise>
				<xs:include>
					<xsl:attribute name="schemaLocation">
						<xsl:value-of select="@egx:from"/>
					</xsl:attribute>
				</xs:include>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*[preceding::*/@egx:from = @egx:from]" mode="eg:imports"/>

	<!-- Element catchers -->
	<xsl:template match="*">
		<xsl:apply-templates select="." mode="eg:elt-real"/>
	</xsl:template>

	<xsl:template match="eg:attribute">
		<xsl:apply-templates select="." mode="eg:attr-real"/>
	</xsl:template>

	<!-- Attribute catchers -->
	<xsl:template match="@*"/>

	<xsl:template match="xs:*/@*">
		<xsl:copy/>
	</xsl:template>

	<!-- Text catcher -->
	<xsl:template match="text()"/>

	<!-- Documentation -->
	<xsl:template match="egx:docs" mode="eg:docs">
		<xs:annotation>
			<xs:documentation>
				<xsl:value-of select="normalize-space(.)"/>
			</xs:documentation>
		</xs:annotation>
	</xsl:template>

	<!-- Assertions -->
	<xsl:template match="*[@eg:assert]" mode="eg:asserts">
		<xs:assert>
			<xsl:attribute name="test">
				<xsl:value-of select="@eg:assert"/>
			</xsl:attribute>
		</xs:assert>
	</xsl:template>

	<xsl:template match="text()|*|@*" mode="eg:asserts"/>

	<!-- Element definitions -->
	<xsl:template match="*" mode="eg:elt-real">
		<xsl:choose>
			<!-- 2nd+ in a sequence of identical elements: ignore -->
			<xsl:when test="preceding-sibling::*[1][local-name(.)=local-name(current()) and namespace-uri(.) = namespace-uri(current()) and not(@eg:occurs)] and not(@eg:occurs)"/>
			<!-- 1st in a sequence of identical elements: apply maxOccurs=unbounded -->
			<xsl:when test="following-sibling::*[1][local-name(.)=local-name(current()) and namespace-uri(.) = namespace-uri(current()) and not(@eg:occurs)] and not(@eg:occurs)">
				<xs:element name="{local-name(.)}">
					<xsl:attribute name="maxOccurs">unbounded</xsl:attribute>
					<xsl:apply-templates select="." mode="eg:elt-default"/>
				</xs:element>
			</xsl:when>
			<xsl:otherwise>
				<xs:element name="{local-name(.)}">
					<xsl:apply-templates select="." mode="eg:elt-occurs"/>
					<xsl:apply-templates select="." mode="eg:elt-default"/>
				</xs:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*[@egx:from]" mode="eg:elt-real">
		<xs:element>
			<xsl:attribute name="ref">
				<xsl:value-of select="name(.)"/>
			</xsl:attribute>
			<xsl:apply-templates select="." mode="eg:elt-occurs"/>
			<xsl:copy-of select="./namespace::*[. = namespace-uri(current())]"/>
		</xs:element>
	</xsl:template>

	<xsl:template match="*[@eg:occurs='-']" mode="eg:elt-real"/>

	<xsl:template match="eg:*|egx:*" mode="eg:elt-real"/>

	<xsl:template match="xs:*" mode="eg:elt-real">
		<xsl:copy>
			<xsl:apply-templates select="*|@*"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="xs:anyAttribute" mode="eg:elt-real"/>

	<!-- Element occurrences -->
	<xsl:template match="*[@eg:occurs='?']" mode="eg:elt-occurs">
		<xsl:attribute name="minOccurs">0</xsl:attribute>
	</xsl:template>

	<xsl:template match="*[@eg:occurs='+']" mode="eg:elt-occurs">
		<xsl:attribute name="maxOccurs">unbounded</xsl:attribute>
	</xsl:template>

	<xsl:template match="*[@eg:occurs='*']" mode="eg:elt-occurs">
		<xsl:attribute name="maxOccurs">unbounded</xsl:attribute>
		<xsl:attribute name="minOccurs">0</xsl:attribute>
	</xsl:template>

	<xsl:template match="*" mode="eg:elt-occurs"/>

	<!-- Element default values -->
	<xsl:template match="*" mode="eg:elt-default">
		<xsl:variable name="val">
			<xsl:value-of select="normalize-space(text()[1])"/>
		</xsl:variable>
		<xsl:if test="substring($val,1,1) = '[' and substring($val,string-length($val),1) = ']'">
			<xsl:attribute name="default">
				<xsl:value-of select="substring($val,2,string-length($val)-2)"/>
			</xsl:attribute>
		</xsl:if>
		<xsl:apply-templates select="." mode="eg:elt-type-ref"/>
	</xsl:template>

	<!-- Element reference or type? -->
	<xsl:template match="*[@eg:define]" mode="eg:elt-type-ref" priority="4">
		<xsl:apply-templates select="@eg:define" mode="eg:reference-type-attr"/>
		<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
	</xsl:template>

	<xsl:template match="*[@eg:content[not(starts-with(.,'xsd:') or starts-with(.,'dtd:')
		or starts-with(.,'eg:') or starts-with(.,'egx:'))]]" mode="eg:elt-type-ref" priority="3">
		<xsl:apply-templates select="@eg:content" mode="eg:reference-type-attr"/>
		<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
	</xsl:template>

	<xsl:template match="*" mode="eg:elt-type-ref">
		<xsl:apply-templates select="." mode="eg:elt-type"/>
	</xsl:template>

	<!-- What type of type? -->
	<xsl:template match="*" mode="eg:elt-type">
		<xsl:variable name="restriction">
			<xsl:call-template name="eg:checkRestriction">
				<xsl:with-param name="val" select="normalize-space(text()[1])"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="*[not(self::eg:*) and not(self::egx:*)]
				and not(starts-with(@eg:content, 'xsd:') or starts-with(@eg:content, 'dtd:'))">
				<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
				<xsl:apply-templates select="." mode="eg:elt-complex-type"/>
			</xsl:when>
			<xsl:when test="eg:attribute or @*[namespace-uri() != $eg-uri and namespace-uri() != $egx-uri]">
				<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
				<xsl:apply-templates select="." mode="eg:elt-complex-type"/>
			</xsl:when>
			<xsl:when test="text() and $restriction = 'true'">
				<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
				<xsl:apply-templates select="."  mode="eg:simple-type"/>
			</xsl:when>
			<xsl:when test="not(text())">
				<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="."  mode="eg:simple-type-attr"/>
				<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Element complex type definition -->
	<xsl:template match="*" mode="eg:elt-complex-type">
		<xs:complexType>
			<xsl:apply-templates select="." mode="eg:simple-complex-content-splitter"/>
		</xs:complexType>
	</xsl:template>

	<!-- Type definitions -->
	<xsl:template match="*" mode="eg:def">
		<xsl:variable name="restriction">
			<xsl:call-template name="eg:checkRestriction">
				<xsl:with-param name="val" select="normalize-space(text()[1])"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="*[not(self::eg:*) and not(self::egx:*)]
				and not(starts-with(@eg:content, 'xsd:') or starts-with(@eg:content, 'dtd:'))">
				<xsl:apply-templates select="." mode="eg:def-complex-type"/>
			</xsl:when>
			<xsl:when test="eg:attribute or @*[namespace-uri() != $eg-uri and namespace-uri() != $egx-uri]">
				<xsl:apply-templates select="." mode="eg:def-complex-type"/>
			</xsl:when>
			<xsl:when test="text() and $restriction = 'true'">
				<xsl:apply-templates select="."  mode="eg:def-simple-type"/>
			</xsl:when>
			<xsl:when test="not(text())"/>
			<xsl:otherwise>
				<xsl:apply-templates select="."  mode="eg:def-simple-type"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="eg:attribute" mode="eg:def">
		<xsl:apply-templates select="."  mode="eg:def-simple-type"/>
	</xsl:template>

	<xsl:template match="*" mode="eg:def-complex-type">
		<xs:complexType name="{@eg:define}">
			<xsl:apply-templates select="." mode="eg:simple-complex-content-splitter"/>
		</xs:complexType>
	</xsl:template>

	<xsl:template match="*[contains(@eg:define,':')]" mode="eg:def-complex-type">
		<xs:complexType name="{substring-after(@eg:define,':')}">
			<xsl:apply-templates select="." mode="eg:simple-complex-content-splitter"/>
		</xs:complexType>
	</xsl:template>

	<!-- Simple content: no child elements, but with attributes and text -->
	<xsl:template match="*[not(*[not(self::eg:*) and not(self::egx:*)]) and (eg:attribute or @*) and text()]" mode="eg:simple-complex-content-splitter" priority="2">
		<xsl:apply-templates select="." mode="eg:elt-simple-content"/>
	</xsl:template>

	<xsl:template match="*[@eg:content[starts-with(., 'xsd:') or starts-with(., 'dtd:')]]" mode="eg:simple-complex-content-splitter" priority="1">
		<xsl:apply-templates select="." mode="eg:elt-simple-content"/>
	</xsl:template>

	<!-- Attributes only -->
	<xsl:template match="*[not(*[not(self::eg:*) and not(self::egx:*)]) and (eg:attribute or @*) and not(text())]" mode="eg:simple-complex-content-splitter">
		<xsl:apply-templates select="*|@*" mode="eg:attr-real"/>
		<xsl:apply-templates select="." mode="eg:asserts"/>
	</xsl:template>

	<!-- Otherwise, get a content model -->
	<xsl:template match="*" mode="eg:simple-complex-content-splitter">
		<xsl:apply-templates select="." mode="eg:elt-mixed"/>
		<xsl:apply-templates select="." mode="eg:elt-model"/>
		<xsl:apply-templates select="*|@*" mode="eg:attr-real"/>
		<xsl:apply-templates select="." mode="eg:asserts"/>
	</xsl:template>

	<!-- Detect mixed content -->
	<xsl:template match="*[text() and *[not(self::eg:*) and not(self::egx:*)]]" mode="eg:elt-mixed" priority="2">
		<xsl:attribute name="mixed">true</xsl:attribute>
	</xsl:template>

	<xsl:template match="*[@eg:content = 'eg:mixed']" mode="eg:elt-mixed" priority="1">
		<xsl:attribute name="mixed">true</xsl:attribute>
	</xsl:template>

	<xsl:template match="*" mode="eg:elt-mixed"/>

	<!-- Complex content model -->
	<xsl:template match="*[@eg:content = 'eg:interleave']" mode="eg:elt-model">
		<xs:all>
			<xsl:apply-templates select="*" mode="eg:elt-real"/>
		</xs:all>
	</xsl:template>

	<xsl:template match="*[@eg:content = 'egx:choice']" mode="eg:elt-model">
		<xs:choice>
			<xsl:apply-templates select="*" mode="eg:elt-real"/>
		</xs:choice>
	</xsl:template>

	<xsl:template match="*[@eg:content = 'eg:group']" mode="eg:elt-model">
		<xs:sequence>
			<xsl:apply-templates select="*" mode="eg:elt-real"/>
		</xs:sequence>
	</xsl:template>

	<xsl:template match="*[@eg:content = 'eg:mixed']" mode="eg:elt-model">
		<xs:all>
			<xsl:apply-templates select="*" mode="eg:elt-real"/>
		</xs:all>
	</xsl:template>

	<xsl:template match="*[not(@eg:content) and text() and *[not(self::eg:*) and not(self::egx:*)]]" mode="eg:elt-model">
		<xs:all>
			<xsl:apply-templates select="*" mode="eg:elt-real"/>
		</xs:all>
	</xsl:template>

	<xsl:template match="*" mode="eg:elt-model">
		<xs:sequence>
			<xsl:apply-templates select="*" mode="eg:elt-real"/>
		</xs:sequence>
	</xsl:template>

	<!-- Simple content -->
	<xsl:template match="*" mode="eg:elt-simple-content">
		<xsl:variable name="restriction">
			<xsl:call-template name="eg:checkRestriction">
				<xsl:with-param name="val" select="normalize-space(text())"/>
			</xsl:call-template>
		</xsl:variable>
		<xs:simpleContent>
			<xsl:choose>
				<xsl:when test="$restriction = 'true'">
					<xs:restriction base="xs:anyType">
						<xsl:apply-templates select="." mode="eg:simple-type"/>
						<xsl:apply-templates select="*|@*" mode="eg:attr-real"/>
						<xsl:apply-templates select="." mode="eg:asserts"/>
					</xs:restriction>
				</xsl:when>
				<xsl:otherwise>
					<xs:extension>
						<xsl:apply-templates select="." mode="eg:base-type-attr"/>
						<xsl:apply-templates select="*|@*" mode="eg:attr-real"/>
						<xsl:apply-templates select="." mode="eg:asserts"/>
					</xs:extension>
				</xsl:otherwise>
			</xsl:choose>
		</xs:simpleContent>
	</xsl:template>

	<!-- Attribute existence -->
	<xsl:template match="@*|eg:attribute" mode="eg:attr-real">
		<xs:attribute>
			<xsl:attribute name="name">
				<xsl:apply-templates select="." mode="eg:attr-name"/>
			</xsl:attribute>
			<xsl:apply-templates select="." mode="eg:attr-defaults"/>
			<xsl:apply-templates select="." mode="eg:attr-occurs"/>
			<xsl:apply-templates select="." mode="eg:attr-type-ref"/>
		</xs:attribute>
	</xsl:template>

	<xsl:template match="xs:anyAttribute" mode="eg:attr-real">
		<xsl:copy>
			<xsl:apply-templates select="*|@*"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="eg:attribute[@eg:occurs='-']" mode="eg:attr-real"/>

	<xsl:template match="*|@eg:*|@egx:*|eg:*/@*|egx:*/@*|xs:*/@*" mode="eg:attr-real"/>

	<!-- Attribute names -->
	<xsl:template match="@*" mode="eg:attr-name">
		<xsl:value-of select="local-name(.)"/>
	</xsl:template>

	<xsl:template match="eg:attribute" mode="eg:attr-name">
		<xsl:value-of select="@name"/>
	</xsl:template>

	<xsl:template match="eg:attribute[contains(@name,':')]" mode="eg:attr-name">
		<xsl:value-of select="substring-after(@name,':')"/>
	</xsl:template>

	<!-- Attribute defaults -->
	<xsl:template match="eg:attribute" mode="eg:attr-defaults">
		<!-- An attribute can't be required and have defaults. Requiredness has priority -->
		<xsl:if test="@eg:occurs = '?' or @eg:occurs = '*'">
			<xsl:apply-templates select="text()" mode="eg:attr-build-default"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="@*" mode="eg:attr-defaults">
		<xsl:apply-templates select="." mode="eg:attr-build-default"/>
	</xsl:template>

	<xsl:template match="text()|@*" mode="eg:attr-build-default">
		<xsl:variable name="val" select="normalize-space(.)"/>
		<xsl:if test="substring($val,1,1) = '[' and substring($val,string-length($val),1) = ']'">
			<xsl:attribute name="default">
				<xsl:value-of select="substring($val,2,string-length($val)-2)"/>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>

	<!-- Attribute occurrence -->
	<xsl:template match="eg:attribute" mode="eg:attr-occurs">
		<xsl:variable name="val" select="normalize-space(text())"/>
		<xsl:if test="not(@eg:occurs = '?' or @eg:occurs = '*')">
			<xsl:attribute name="use">required</xsl:attribute>
		</xsl:if>
	</xsl:template>

	<xsl:template match="@*" mode="eg:attr-occurs"/>

	<!-- Attribute reference or type? -->
	<xsl:template match="eg:attribute[@eg:define]" mode="eg:attr-type-ref">
		<xsl:apply-templates select="@eg:define" mode="eg:reference-type-attr"/>
		<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
	</xsl:template>

	<xsl:template match="eg:attribute[@eg:content[not(starts-with(.,'xsd:') or starts-with(.,'dtd:')
		or starts-with(.,'eg:') or starts-with(.,'egx:'))]]" mode="eg:attr-type-ref">
		<xsl:apply-templates select="@eg:content" mode="eg:reference-type-attr"/>
		<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
	</xsl:template>

	<xsl:template match="eg:attribute|@*" mode="eg:attr-type-ref">
		<xsl:apply-templates select="."  mode="eg:attr-type"/>
	</xsl:template>

	<!-- Attribute type type -->
	<xsl:template match="eg:attribute" mode="eg:attr-type">
		<xsl:variable name="restriction">
			<xsl:call-template name="eg:checkRestriction">
				<xsl:with-param name="val" select="normalize-space(text()[1])"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$restriction = 'true'">
				<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
				<xsl:apply-templates select="."  mode="eg:simple-type"/>
			</xsl:when>
			<xsl:when test="not(text())">
				<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="."  mode="eg:simple-type-attr"/>
				<xsl:apply-templates select="egx:docs" mode="eg:docs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@*" mode="eg:attr-type">
		<xsl:variable name="restriction">
			<xsl:call-template name="eg:checkRestriction">
				<xsl:with-param name="val" select="normalize-space(.)"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$restriction = 'true'">
				<xsl:apply-templates select="."  mode="eg:simple-type"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="."  mode="eg:simple-type-attr"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@*" mode="eg:reference-type-attr">
		<xsl:if test="contains(.,':')">
			<xsl:copy-of select="/*/namespace::*[name() = substring-before(current(),':')]"/>
		</xsl:if>
		<xsl:attribute name="type">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="*|text()|@*" mode="eg:simple-type-attr">
		<xsl:attribute name="type">
			<xsl:apply-templates select="." mode="eg:atomic-type"/>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="*|@*" mode="eg:simple-type">
		<xs:simpleType>
			<xsl:apply-templates select="." mode="eg:restriction-builder"/>
		</xs:simpleType>
	</xsl:template>

	<xsl:template match="*" mode="eg:def-simple-type">
		<xs:simpleType name="{@eg:define}">
			<xsl:apply-templates select="." mode="eg:restriction-builder"/>
		</xs:simpleType>
	</xsl:template>

	<xsl:template match="*[contains(@eg:define,':')]" mode="eg:def-simple-type">
		<xs:simpleType name="{substring-after(@eg:define,':')}">
			<xsl:apply-templates select="." mode="eg:restriction-builder"/>
		</xs:simpleType>
	</xsl:template>

	<xsl:template match="*|text()|@*" mode="eg:restriction-builder">
		<xs:restriction>
			<xsl:apply-templates select="." mode="eg:base-type-attr"/>
			<xsl:apply-templates select="." mode="eg:restriction-contents-builder"/>
		</xs:restriction>
	</xsl:template>

	<xsl:template match="*|text()|@*" mode="eg:base-type-attr">
		<xsl:attribute name="base">
			<xsl:apply-templates select="." mode="eg:atomic-type"/>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="*" mode="eg:restriction-contents-builder">
		<xsl:apply-templates select="text()" mode="eg:restriction-contents-builder"/>
	</xsl:template>

	<xsl:template match="text()|@*" mode="eg:restriction-contents-builder">
		<xsl:variable name="val">
			<xsl:value-of select="normalize-space(.)"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="substring($val,1,1) = '/' and substring($val,string-length($val),1) = '/'">
				<xsl:call-template name="eg:createPattern">
					<xsl:with-param name="val" select="substring($val,2,string-length($val)-2)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="substring($val,1,1) = '|' and substring($val,string-length($val),1) = '|'">
				<xsl:call-template name="eg:createEnum">
					<xsl:with-param name="val" select="substring($val,2,string-length($val)-2)"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*" mode="eg:atomic-type">
		<xsl:choose>
			<xsl:when test="@eg:content[starts-with(normalize-space(.),'xsd:') or starts-with(normalize-space(.),'dtd:')]">
				<xsl:value-of select="concat('xs:',substring(normalize-space(@eg:content),5))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="text()[1]" mode="eg:atomic-type"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@*[(substring(normalize-space(.),1,5) = '{xsd:' or substring(normalize-space(.),1,5) = '{dtd:')
		and substring(normalize-space(.), string-length(normalize-space(.)),1) = '}']" mode="eg:atomic-type">
		<xsl:value-of select="concat('xs:',substring(normalize-space(.),6,string-length(normalize-space(.))-6))"/>
	</xsl:template>

	<xsl:template match="text()|@*" mode="eg:atomic-type">
		<xsl:variable name="val" select="normalize-space(.)"/>
		<xsl:variable name="enum">
			<xsl:if test="substring($val,1,1) = '|' and substring($val,string-length($val),1) = '|'">true</xsl:if>
		</xsl:variable>
		<xsl:variable name="default">
			<xsl:if test="substring($val,1,1) = '[' and substring($val,string-length($val),1) = ']'">true</xsl:if>
		</xsl:variable>
		<xsl:variable name="valOut">
			<xsl:choose>
				<xsl:when test="$enum = 'true'">
					<xsl:value-of select="substring-before(substring($val,2),'|')"/>
				</xsl:when>
				<xsl:when test="$default = 'true'">
					<xsl:value-of select="substring($val,2,string-length($val)-2)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$val"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="eg:checkType">
			<xsl:with-param name="val" select="$valOut"/>
			<xsl:with-param name="enum" select="$enum"/>
		</xsl:call-template>
	</xsl:template>

	<!-- Type Checker -->
	<xsl:template name="eg:checkType">
		<xsl:param name="val"/>
		<xsl:param name="enum"/>
		<xsl:variable name="isDecimal">
			<xsl:call-template name="eg:checkDecimal">
				<xsl:with-param name="val" select="$val"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$val = ''">xs:string</xsl:when>
			<xsl:when test="$isDecimal = 'xs:int'">xs:integer</xsl:when>
			<xsl:when test="$isDecimal = 'xs:decimal'">xs:decimal</xsl:when>
			<xsl:when test="$val = 'true' or $val = 'false'">xs:boolean</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="isDouble">
					<xsl:call-template name="eg:checkDouble">
						<xsl:with-param name="val" select="$val"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$isDouble = 'xs:double'">xs:double</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="isDate">
							<xsl:call-template name="eg:checkDate">
								<xsl:with-param name="val" select="$val"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="$isDate != ''">
								<xsl:value-of select="$isDate"/>
							</xsl:when>
							<xsl:when test="$enum = 'true'">xs:token</xsl:when>
							<xsl:otherwise>xs:string</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="eg:checkDecimal">
		<xsl:param name="val" select="normalize-space(.)"/>
		<xsl:variable name="leading" select="translate(substring($val, 1, 1), '-', '+')"/>
		<xsl:variable name="no-digits" select="translate($val, '0123456789', '')"/>
		<xsl:variable name="no-digits2" select="translate($no-digits, '-', '+')"/>
		<xsl:choose>
			<xsl:when test="$no-digits = '' or ($no-digits2='+' and $leading='+')">
				<xsl:text>xs:int</xsl:text>
			</xsl:when>
			<xsl:when test="$no-digits = '.' or ($no-digits2='+.' and $leading='+')">
				<xsl:text>xs:decimal</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>no</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="eg:checkDouble">
		<xsl:param name="val"/>
		<xsl:if test="contains($val, 'E')">
			<xsl:variable name="n">
				<xsl:call-template name="eg:checkDecimal">
					<xsl:with-param name="val" select="substring-before($val, 'E')"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="m">
				<xsl:call-template name="eg:checkDecimal">
					<xsl:with-param name="val" select="substring-after($val, 'E')"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:if test="$n != 'no' and $m = 'xs:int'">xs:double</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template name="eg:checkDate">
		<xsl:param name="val" select="normalize-space(.)"/>
		<xsl:variable name="no-digits" select="translate(translate($val, '#', '!'), '0123456789', '##########')"/>
		<xsl:choose>
			<xsl:when
				test="$no-digits = '####-##-##'
				or $no-digits = '####-##-##Z'
				or $no-digits = '####-##-##+##:##'
				or $no-digits = '####-##-##-##:##'"
				>xs:date</xsl:when>
			<xsl:when
				test="$no-digits = '####-##-##T##:##:##'
				or $no-digits = '####-##-##T##:##:##Z'
				or $no-digits = '####-##-##T##:##:##+##:##'
				or $no-digits = '####-##-##T##:##:##-##:##'"
				>xs:dateTime</xsl:when>
			<xsl:when
				test="$no-digits = '##:##:##'
				or $no-digits = '##:##:##Z'
				or $no-digits = '##:##:##+##:##'
				or $no-digits = '##:##:##-##:##'"
				>xs:time</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="eg:createEnum">
		<xsl:param name="val" select="normalize-space(.)"/>
		<xsl:if test="string-length($val)">
			<xs:enumeration value="{normalize-space(substring-before(concat($val,'|'), '|'))}"/>
			<xsl:call-template name="eg:createEnum">
				<xsl:with-param name="val" select="substring-after($val,'|')"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="eg:createPattern">
		<xsl:param name="val" select="normalize-space(.)"/>
		<xs:pattern value="{$val}"/>
	</xsl:template>

	<xsl:template name="eg:checkRestriction">
		<xsl:param name="val"/>
		<xsl:choose>
			<xsl:when test="substring($val,1,1) = '|' and substring($val,string-length($val),1) = '|'">true</xsl:when>
			<xsl:when test="substring($val,1,1) = '/' and substring($val,string-length($val),1) = '/'">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>