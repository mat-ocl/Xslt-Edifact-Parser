<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns="http://www.clankysoftware.com/xslt/edifactparser"
                expand-text="yes"
                version="2.0">
    
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="edifact">
        <!-- Define the UNA line -->
        <xsl:variable name="myu">
            <xsl:choose>
                <xsl:when test="substring(., 1, 3) = 'UNA'">
                    <xsl:value-of select="substring(., 4, 6)"/>
                </xsl:when>
                <xsl:otherwise>:+.? '</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Define the variables for UNA -->
        <xsl:variable name="subdel" select="substring($myu, 1, 1)"/>
        <xsl:variable name="datadel" select="substring($myu, 2, 1)"/>
        <xsl:variable name="decind" select="substring($myu, 3, 1)"/>
        <xsl:variable name="release" select="substring($myu, 4, 1)"/>
        <xsl:variable name="reserved" select="substring($myu, 5, 1)"/>
        <xsl:variable name="segmentdel" select="substring($myu, 6, 1)"/>
        
        <!-- Output the UNA comments -->
        <xsl:text>&#10;</xsl:text>
        <xsl:choose>
            <xsl:when test="substring(., 1, 3) = 'UNA'">
                <xsl:comment>UNA segment found</xsl:comment><xsl:text>&#10;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>Using default UNA</xsl:comment><xsl:text>&#10;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        
        <xsl:comment>Sub-element delimiter &gt;<xsl:value-of select="$subdel"/>&lt;</xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Data element delimiter &gt;<xsl:value-of select="$datadel"/>&lt;</xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Decimal point indicator &gt;<xsl:value-of select="$decind"/>&lt;</xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Release character &gt;<xsl:value-of select="$release"/>&lt; </xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Reserved for future use &gt;<xsl:value-of select="$reserved"/>&lt;</xsl:comment><xsl:text>&#10;</xsl:text>
        <xsl:comment>Segment terminator &gt;<xsl:value-of select="$segmentdel"/>&lt;</xsl:comment><xsl:text>&#10;&#10;   </xsl:text>
        
        <!-- Construct the edifact XML -->
        <xsl:element name="edifact">
            
            <xsl:for-each select="tokenize(normalize-space(.), concat('[', $segmentdel, ']'))">
                <xsl:variable name="editag" select="substring(normalize-space(.), 1, 3)"/>
                <xsl:variable name="ediline" select="substring-after(normalize-space(.), concat($editag,$datadel) )"/>
                
                <xsl:choose>
                    <xsl:when test="$editag != 'UNA'">
                        <xsl:if test="$editag != ''">
                            <xsl:element name="{$editag}">
                                <xsl:for-each select="tokenize(normalize-space($ediline), concat('[', $datadel, ']'))">
                                    <xsl:variable name="subtag" select="concat($editag, format-number(position(), '00'))"/>
                                    
                                    <xsl:for-each select="tokenize(normalize-space(.), concat('[', $subdel, ']'))">
                                        <xsl:variable name="innertag" select="concat($subtag, '.', format-number(position(), '00'))"/>
                                        <xsl:if test=". != ''">
                                            <xsl:element name="{$innertag}">
                                                <xsl:value-of select="."/>
                                            </xsl:element>
                                        </xsl:if>
                                    </xsl:for-each>
                                    
                                </xsl:for-each>
                            </xsl:element>
                        </xsl:if>
                    </xsl:when>
                    
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
