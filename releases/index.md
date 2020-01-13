# Releases

{% assign buildinfo = site.pages | where_exp: "item" , "item.path contains 'testmain.md'" %}
{% for page in buildinfo %}
{% assign dirs = page.path | split: "/" | reverse %}
{% assign tag = dirs[2] %}
{% assign version = tag %}

* Version [{{ version }}]({{ tag }}/)

{% endfor %}
