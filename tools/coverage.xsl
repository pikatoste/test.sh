<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
    <xsl:template match="/">
        <xsl:value-of select="descendant::td[a/@title='test.sh']/following-sibling::td"/>
    </xsl:template>

</xsl:stylesheet>
