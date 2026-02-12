# EDIFACT to XML Transformation XSLT

This document describes the XSLT transformation designed to parse and transform EDIFACT messages into XML format.

## Overview

The transformation process involves parsing the EDIFACT message, identifying and extracting its components based on the UNA segment (if present), and then constructing an XML representation of the message.

## UNA Line Definition

The UNA line, if present, specifies the special characters used in the EDIFACT message, including:

- Sub-element delimiter
- Data element delimiter
- Decimal indicator
- Release character
- Reserved character
- Segment terminator

If the UNA line is not present, default values are used.

## Variables for UNA

The following variables are defined based on the UNA line or default values:

- `subdel`: Sub-element delimiter
- `datadel`: Data element delimiter
- `decind`: Decimal indicator
- `release`: Release character
- `reserved`: Reserved character
- `segmentdel`: Segment terminator

## Output UNA Comments

Comments are outputted to indicate whether a UNA segment was found or if default values are being used, along with the values of the UNA variables.

## Constructing the EDIFACT XML

The EDIFACT message is tokenized into segments using the segment terminator. Each segment is then processed to extract its tag and data elements. Data elements are further tokenized into sub-elements. An XML structure is constructed with elements named according to the segment tag and position numbers for data elements and sub-elements.

## Example Transformation

```xml
<edifact>
    <UNH>
        <UNH01.01>MessageHeader</UNH01.01>
        <UNH02.01>MessageType</UNH02.01>
    </UNH>
    <DTM>
        <DTM01.01>Date/Time/Period</DTM01.01>
    </DTM>
</edifact>
```
This example shows a simplified XML representation of an EDIFACT message with UNH (Message Header) and DTM (Date/Time/Period) segments.

## Enhanced Example Transformation

Given the more complex EDIFACT message in `test.xml`, the XML transformation would look like this:


```xml
<edifact>
    <UNB>
        <UNB01.01>UNOC</UNB01.01>
        <UNB02.01>3</UNB02.01>
        <UNB03.01>1234567890123</UNB03.01>
        <UNB03.02>14</UNB03.02>
        <UNB04.01>9876543210987</UNB04.01>
        <UNB04.02>14</UNB04.02>
        <UNB05.01>030101</UNB05.01>
        <UNB05.02>1234</UNB05.02>
        <UNB06.01>1</UNB06.01>
        <UNB07.01>1</UNB07.01>
        <UNB08.01>1</UNB08.01>
    </UNB>
    <UNH>
        <UNH01.01>1</UNH01.01>
        <UNH02.01>INVOIC</UNH02.01>
        <UNH02.02>D</UNH02.02>
        <UNH02.03>96A</UNH02.03>
        <UNH02.04>UN</UNH02.04>
        <UNH02.05>1.6</UNH02.05>
    </UNH>
    <BGM>
        <BGM01.01>380</BGM01.01>
        <BGM02.01>342459</BGM02.01>
        <BGM03.01>9</BGM03.01>
    </BGM>
    <DTM>
        <DTM01.01>3</DTM01.01>
        <DTM02.01>20050101</DTM02.01>
        <DTM02.02>102</DTM02.02>
    </DTM>
    <RFF>
        <RFF01.01>ON</RFF01.01>
        <RFF02.01>612345</RFF02.01>
    </RFF>
    <NAD>
        <NAD01.01>BY</NAD01.01>
        <NAD04.01>High Street</NAD04.01>
        <NAD04.02>Building Name</NAD04.02>
        <NAD04.03>City Name</NAD04.03>
        <NAD05.01>AA11AA</NAD05.01>
    </NAD>
</edifact>
```

This enhanced example demonstrates a more detailed transformation, including various segments like `UNB` (Beginning of Message), `UNH` (Message Header), `BGM` (Beginning of Message), `DTM` (Date/Time/Period), `RFF` (Reference), `NAD` (Name and Address), `CTA` (Contact Information), `COM` (Communication Contact), `UNT` (Message Trailer), and `UNZ` (Interchange Trailer), providing a comprehensive view of how an EDIFACT message is transformed into XML.
