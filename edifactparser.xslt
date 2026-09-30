<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:funcl="http://www.clankysoftware.com/xslt/functions"
                xmlns="http://www.clankysoftware.com/xslt/edifactparser"
                exclude-result-prefixes="xs funcl"
                version="2.0">
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Function to escape reserved regex characters -->
    <xsl:function name="funcl:escape-regex" as="xs:string">
        <xsl:param name="char" as="xs:string"/>
        <xsl:sequence select="
            if (string-length($char) = 0) then '(?!)'
            else if ($char = '\') then '[\\]'
            else if ($char = ']') then '[\]]'
            else if ($char = '[') then '[\[]'
            else if ($char = '^') then '[\^]'
            else if ($char = '-') then '[\-]'
            else concat('[', $char, ']')
                        "/>
    </xsl:function>
    
    <xsl:template match="*:edifact">
        <xsl:variable name="clean-doc" select="replace(., '^[\s&#160;]+', '')"/>
        <!-- Define the UNA line -->
        <xsl:variable name="has-una" select="starts-with($clean-doc, 'UNA')" />
        <xsl:variable name="myu">
            <xsl:choose>
                <xsl:when test="$has-una">
                    <xsl:value-of select="substring($clean-doc, 4, 6)"/>
                </xsl:when>
                <xsl:otherwise>:+.? '</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Define delimiter variables -->
        <xsl:variable name="subdel" select="substring($myu, 1, 1)"/>
        <xsl:variable name="datadel" select="substring($myu, 2, 1)"/>
        <xsl:variable name="decind" select="substring($myu, 3, 1)"/>
        <xsl:variable name="release" select="substring($myu, 4, 1)"/>
        <xsl:variable name="reserved" select="substring($myu, 5, 1)"/>
        <xsl:variable name="segmentdel" select="substring($myu, 6, 1)"/>
        
        <!-- Escape regex delimiters -->
        <xsl:variable name="regex-release" select="funcl:escape-regex($release)"/>
        <xsl:variable name="regex-seg" select="funcl:escape-regex($segmentdel)"/>
        <xsl:variable name="regex-data" select="funcl:escape-regex($datadel)"/>
        <xsl:variable name="regex-sub" select="funcl:escape-regex($subdel)"/>
        
        <!-- Output the UNA comments -->
        <xsl:text>&#10;</xsl:text>
        <xsl:choose>
            <xsl:when test="$has-una">
                <xsl:comment>UNA segment found</xsl:comment><xsl:text>&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>Using default UNA</xsl:comment><xsl:text>&#10;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        
        <xsl:comment>Sub-element delimiter &gt;<xsl:value-of select="$subdel"/>&lt;</xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Data element delimiter &gt;<xsl:value-of select="$datadel"/>&lt;</xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Decimal point indicator &gt;<xsl:value-of select="$decind"/>&lt;</xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Release character &gt;<xsl:value-of select="$release"/>&lt;</xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Reserved &gt;<xsl:value-of select="$reserved"/>&lt;</xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Segment terminator &gt;<xsl:value-of select="$segmentdel"/>&lt;</xsl:comment><xsl:text>&#10;&#10;</xsl:text>
        
        <!-- Clean up and escape chars in datafields -->
        <xsl:variable name="raw-payload" select="if ($has-una) then substring($clean-doc, 10) else $clean-doc" />
        
        <!-- Mask escaped delimiters -->
        <xsl:variable name="step1" select="replace($raw-payload, concat($regex-release, $regex-release), '&#xE004;')"/>
        <xsl:variable name="step2" select="replace($step1, concat($regex-release, $regex-seg), '&#xE001;')"/>
        <xsl:variable name="step3" select="replace($step2, concat($regex-release, $regex-data), '&#xE002;')"/>
        <xsl:variable name="safe-payload" select="replace($step3, concat($regex-release, $regex-sub), '&#xE003;')"/>
        
        <!-- Construct the edifact XML -->
        <xsl:element name="edifact">
            <xsl:for-each select="tokenize($safe-payload, $regex-seg)">
                <xsl:variable name="segment" select="replace(., '^[\r\n\t&#160; ]+|[\r\n\t&#160; ]+$', '')"/>
                
                <xsl:if test="$segment != ''">
                    <xsl:variable name="data-elements" select="tokenize($segment, $regex-data)"/>
                    <xsl:variable name="editag" select="$data-elements[1]"/>
                    
                    <xsl:if test="matches($editag, '^[a-zA-Z0-9]+$')">
                        <xsl:element name="{$editag}">
                            
                            <xsl:for-each select="$data-elements[position() > 1]">
                                <xsl:variable name="data-pos" select="position()"/>
                                <xsl:variable name="subtag" select="concat($editag, format-number($data-pos, '00'))"/>
                                
                                <!-- Prevent empty data elements from returning () and skipping tag generation -->
                                <xsl:for-each select="if (. = '') then '' else tokenize(., $regex-sub)">
                                    <xsl:variable name="sub-pos" select="position()"/>
                                    <xsl:variable name="innertag" select="concat($subtag, '.', format-number($sub-pos, '00'))"/>
                                    
                                    <xsl:element name="{$innertag}">
                                        <xsl:value-of select="translate(., '&#xE004;&#xE001;&#xE002;&#xE003;', concat($release, $segmentdel, $datadel, $subdel))"/>
                                    </xsl:element>
                                </xsl:for-each>
                                
                            </xsl:for-each>
                        </xsl:element>
                    </xsl:if>
                </xsl:if>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>