.syntax_comment {color: #808000;}
.syntax_comment_mysql {}
.syntax_comment_ansi {}
.syntax_comment_c {}
.syntax_digit {}
.syntax_digit_hex {color: teal;}
.syntax_digit_integer {color: teal;}
.syntax_digit_float {color: aqua;}
.syntax_punct {color: fuchsia;}
.syntax_alpha {}
.syntax_alpha_columnType {color: #f90;}
.syntax_alpha_columnAttrib {color: #00f;}
.syntax_alpha_reservedWord {color: #909;}
.syntax_alpha_functionName {color: #f00;}
.syntax_alpha_identifier {color: black;}
.syntax_alpha_charset {color: #6495ed;}
.syntax_alpha_variable {color: #800000;}
.syntax_quote {color: #008000;}
.syntax_quote_double {}
.syntax_quote_single {}
.syntax_quote_backtick {}
.syntax_indent0 {margin-left: 0em;}
.syntax_indent1 {margin-left: 1em;}
.syntax_indent2 {margin-left: 2em;}
.syntax_indent3 {margin-left: 3em;}
.syntax_indent4 {margin-left: 4em;}
.syntax_indent5 {margin-left: 5em;}
.syntax_indent6 {margin-left: 6em;}
.syntax_indent7 {margin-left: 7em;}

/* FILE: common.css.php */
/******************************************************************************/

/* general tags */
html {
    font-size: 82%}

input,
select,
textarea {
    font-size: 1em;
}


body {
    font-family: sans-serif;
    padding: 0;
    margin: 0;
    margin-left: 240px;
    color: #444;
    background: #fff;
}

body#loginform {
    margin: 0;
}

#page_content {
    margin: 0 .5em;
}

textarea,
tt,
pre,
code {
    font-family: monospace;
}


h1 {
    font-size: 140%;
    font-weight: bold;
}

h2 {
    font-size: 2em;
    font-weight: normal;
    text-shadow: 0 1px 0 #fff;
    padding: 10px 0 10px;
    padding-left: 3px;
    color: #777;
}

/* Hiding icons in the page titles */
h2 img {
    display: none;
}

h2 a img {
    display: inline;
}

.data,
.data_full_width {
    margin: 0 0 12px;
}

.data_full_width {
    width: 100%;
}

#table_results td.data {
border-right: 1px solid #bbb;
}

h3 {
    font-weight: bold;
}

a,
a:link,
a:visited,
a:active {
    text-decoration: none;
    color: #235a81;
    cursor: pointer;
    outline: none;

}

a:hover {
    text-decoration: underline;
    color: #235a81;
}

#initials_table {
    background: #f3f3f3;
    border: 1px solid #aaa;
    margin-bottom: 10px;
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
    border-radius: 5px;
}

#initials_table td {
    padding: 8px !important;
}

#initials_table a {
    border: 1px solid #aaa;
    background: #fff;
    padding: 4px 8px;
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
    border-radius: 5px;
    background-image: url(./themes/svg_gradient.php?from=ffffff&to=cccccc);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#cccccc));
background: -webkit-linear-gradient(top, #ffffff, #cccccc);
background: -moz-linear-gradient(top, #ffffff, #cccccc);
background: -ms-linear-gradient(top, #ffffff, #cccccc);
background: -o-linear-gradient(top, #ffffff, #cccccc);}

dfn {
    font-style: normal;
}

dfn:hover {
    font-style: normal;
    cursor: help;
}

th {
    font-weight: bold;
    color: #000;
    background: #f3f3f3;
    background-image: url(./themes/svg_gradient.php?from=ffffff&to=cccccc);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#cccccc));
background: -webkit-linear-gradient(top, #ffffff, #cccccc);
background: -moz-linear-gradient(top, #ffffff, #cccccc);
background: -ms-linear-gradient(top, #ffffff, #cccccc);
background: -o-linear-gradient(top, #ffffff, #cccccc);}

a img {
    border: 0;
}

hr {
    color: #000;
    background-color: #000;
    border: 0;
    height: 1px;
}

form {
    padding: 0;
    margin: 0;
    display: inline;
}

input[type=text] {
    border-radius: 2px;
    -moz-border-radius: 2px;
    -webkit-border-radius: 2px;

    box-shadow: 0 1px 2px #ddd;
    -moz-box-shadow: 0 1px 2px #ddd;
    -webkit-box-shadow: 0 1px 2px #ddd;

    background: white;
    border: 1px solid #aaa;
    color: #555;
    padding: 4px;
    margin: 6px;

}

input[type=password] {
    border-radius: 2px;
    -moz-border-radius: 2px;
    -webkit-border-radius: 2px;

    box-shadow: 0 1px 2px #ddd;
    -moz-box-shadow: 0 1px 2px #ddd;
    -webkit-box-shadow: 0 1px 2px #ddd;

    background: white;
    border: 1px solid #aaa;
    color: #555;
    padding: 4px;
    margin: 6px;

}

input[type=submit],
button[type=submit]:not(.mult_submit) {
    font-weight: bold !important;
}

input[type=submit],
button[type=submit]:not(.mult_submit),
input[type=reset],
input[name=submit_reset],
input.button {
    margin-left: 14px;
    border: 1px solid #aaa;
    padding: 3px 7px;
    color: #111;
    text-decoration: none;
    background: #ddd;

    border-radius: 12px;
    -webkit-border-radius: 12px;
    -moz-border-radius: 12px;

    text-shadow: 0 1px 0 #fff;

    background-image: url(./themes/svg_gradient.php?from=ffffff&to=cccccc);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#cccccc));
background: -webkit-linear-gradient(top, #ffffff, #cccccc);
background: -moz-linear-gradient(top, #ffffff, #cccccc);
background: -ms-linear-gradient(top, #ffffff, #cccccc);
background: -o-linear-gradient(top, #ffffff, #cccccc);}

input[type=submit]:hover,
button[type=submit]:not(.mult_submit):hover,
input[type=reset]:hover,
input[name=submit_reset]:hover,
input.button:hover {
    position: relative;
    background-image: url(./themes/svg_gradient.php?from=cccccc&to=dddddd);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#cccccc), to(#dddddd));
background: -webkit-linear-gradient(top, #cccccc, #dddddd);
background: -moz-linear-gradient(top, #cccccc, #dddddd);
background: -ms-linear-gradient(top, #cccccc, #dddddd);
background: -o-linear-gradient(top, #cccccc, #dddddd);    cursor: pointer;
}

input[type=submit]:active,
button[type=submit]:not(.mult_submit):active,
input[type=reset]:active,
input[name=submit_reset]:active,
input.button:active {
    position: relative;
    top: 1px;
    left: 1px;
}

textarea {
    overflow: visible;
    height: 18em;
}

textarea.char {
    height: 3em;
}

fieldset {
    margin-top: 1em;
    border-radius: 4px 4px 0 0;
    -moz-border-radius: 4px 4px 0 0;
    -webkit-border-radius: 4px 4px 0 0;
    border: #aaa solid 1px;
    padding: 1.5em;
    background: #eee;
    text-shadow: 1px 1px 2px #fff inset;
    -moz-box-shadow: 1px 1px 2px #fff inset;
    -webkit-box-shadow: 1px 1px 2px #fff inset;
    box-shadow: 1px 1px 2px #fff inset;
}

fieldset fieldset {
    margin: .8em;
    background: #fff;
    border: 1px solid #aaa;
    background: #E8E8E8;

}

fieldset legend {
    font-weight: bold;
    color: #444;
    padding: 5px 10px;
    border-radius: 2px;
    -moz-border-radius: 2px;
    -webkit-border-radius: 2px;
    border: 1px solid #aaa;
    background-color: #fff;
    -moz-box-shadow: 3px 3px 15px #bbb;
    -webkit-box-shadow: 3px 3px 15px #bbb;
    box-shadow: 3px 3px 15px #bbb;
}

.some-margin {
    margin: 1.5em;
}

/* buttons in some browsers (eg. Konqueror) are block elements,
   this breaks design */
button {
    display: inline;
}

table caption,
table th,
table td {
    padding: .3em;
    margin: .1em;
    vertical-align: top;
    text-shadow: 0 1px 0 #fff;
}

/* 3.4 */
table {
    border-collapse: collapse;
}

th {
    border-right: 1px solid #fff;
    text-align: left;
}


img,
button {
    vertical-align: middle;
}

input[type="checkbox"],
input[type="radio"] {
    vertical-align: -11%;
}


select {
    -moz-border-radius: 2px;
    -webkit-border-radius: 2px;
    border-radius: 2px;

    -moz-box-shadow: 0 1px 2px #ddd;
    -webkit-box-shadow: 0 1px 2px #ddd;
    box-shadow: 0 1px 2px #ddd;

    border: 1px solid #aaa;
    color: #333;
    padding: 3px;
    background: white;
}

select[multiple] {
    background-image: url(./themes/svg_gradient.php?from=ffffff&to=f2f2f2);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#f2f2f2));
background: -webkit-linear-gradient(top, #ffffff, #f2f2f2);
background: -moz-linear-gradient(top, #ffffff, #f2f2f2);
background: -ms-linear-gradient(top, #ffffff, #f2f2f2);
background: -o-linear-gradient(top, #ffffff, #f2f2f2);}

/******************************************************************************/
/* classes */
.clearfloat {
    clear: both;
}

.floatleft {
    float: left;
    margin-right: 1em;
}

.floatright {
    float: right;
}

.center {
    text-align: center;
}

table.nospacing {
    border-spacing: 0;
}

table.nopadding tr th, table.nopadding tr td {
    padding: 0;
}

th.left, td.left {
    text-align: left;
}

th.center, td.center {
    text-align: center;
}

th.right, td.right {
    text-align: right;
}

tr.vtop th, tr.vtop td, th.vtop, td.vtop {
    vertical-align: top;
}

tr.vmiddle th, tr.vmiddle td, th.vmiddle, td.vmiddle {
    vertical-align: middle;
}

tr.vbottom th, tr.vbottom td, th.vbottom, td.vbottom {
    vertical-align: bottom;
}

.paddingtop {
    padding-top: 1em;
}

.separator {
    color: #fff;
    text-shadow: 0 1px 0 #000;
}

div.tools {
    /* border: 1px solid #000; */
    padding: .2em;
}

div.tools a {
    color: #3a7ead !important;
}

div.tools,
fieldset.tblFooters {
    margin-top: 0;
    margin-bottom: .5em;
    /* avoid a thick line since this should be used under another fieldset */
    border-top: 0;
    text-align: right;
    float: none;
    clear: both;
    -webkit-border-radius: 0 0 4px 4px;
    -moz-border-radius: 0 0 4px 4px;
    border-radius: 0 0 4px 5px;
}

div.null_div {
    height: 20px;
    text-align: center;
    font-style: normal;
    min-width: 50px;
}

fieldset .formelement {
    float: left;
    margin-right: .5em;
    /* IE */
    white-space: nowrap;
}

/* revert for Gecko */
fieldset div[class=formelement] {
    white-space: normal;
}

button.mult_submit {
    border: none;
    background-color: transparent;
}

/* odd items 1,3,5,7,... */
table tr.odd th,
.odd {
    background: #fff;
    }

/* even items 2,4,6,8,... */
/* (tested on CRTs and ACLs) */
table tr.even th,
.even {
    background: #DFDFDF;
    }

/* odd table rows 1,3,5,7,... */
table tr.odd th,
table tr.odd,
table tr.even th,
table tr.even {
    text-align: left;
}

/* marked table rows */
td.marked,
table tr.marked td,
table tr.marked th,
table tr.marked {
    background-image: url(./themes/svg_gradient.php?from=ced6df&to=b6c6d7);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ced6df), to(#b6c6d7));
background: -webkit-linear-gradient(top, #ced6df, #b6c6d7);
background: -moz-linear-gradient(top, #ced6df, #b6c6d7);
background: -ms-linear-gradient(top, #ced6df, #b6c6d7);
background: -o-linear-gradient(top, #ced6df, #b6c6d7);    color: #000;
}

/* hovered items */
.odd:hover,
.even:hover,
.hover {
    background-image: url(./themes/svg_gradient.php?from=ced6df&to=b6c6d7);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ced6df), to(#b6c6d7));
background: -webkit-linear-gradient(top, #ced6df, #b6c6d7);
background: -moz-linear-gradient(top, #ced6df, #b6c6d7);
background: -ms-linear-gradient(top, #ced6df, #b6c6d7);
background: -o-linear-gradient(top, #ced6df, #b6c6d7);    color: #000;
}

/* hovered table rows */
table tr.odd:hover th,
table tr.even:hover th,
table tr.hover th {
    background-image: url(./themes/svg_gradient.php?from=ced6df&to=b6c6d7);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ced6df), to(#b6c6d7));
background: -webkit-linear-gradient(top, #ced6df, #b6c6d7);
background: -moz-linear-gradient(top, #ced6df, #b6c6d7);
background: -ms-linear-gradient(top, #ced6df, #b6c6d7);
background: -o-linear-gradient(top, #ced6df, #b6c6d7);    color: #000;
}

/**
 * marks table rows/cells if the db field is in a where condition
 */
.condition {
    border-color: #fc9 !important;
}

th.condition {
    border-width: 1px 1px 0 1px;
    border-style: solid;
}

td.condition {
    border-width: 0 1px 0 1px;
    border-style: solid;
}

tr:last-child td.condition {
    border-width: 0 1px 1px 1px;
}

/* for first th which must have right border set (ltr only) */
.before-condition {
    border-right: 1px solid #fc9;
}

/**
 * cells with the value NULL
 */
td.null {
    font-style: italic;
    text-align: right;
}

table .valueHeader {
    text-align: right;
    white-space: normal;
}
table .value {
    text-align: right;
    white-space: normal;
}
/* IE doesnt handles 'pre' right */
table [class=value] {
    white-space: normal;
}


.value {
    font-family: monospace;
}
.attention {
    color: red;
    font-weight: bold;
}
.allfine {
    color: green;
}


img.lightbulb {
    cursor: pointer;
}

.pdflayout {
    overflow: hidden;
    clip: inherit;
    background-color: #fff;
    display: none;
    border: 1px solid #000;
    position: relative;
}

.pdflayout_table {
    background: #D3DCE3;
    color: #000;
    overflow: hidden;
    clip: inherit;
    z-index: 2;
    display: inline;
    visibility: inherit;
    cursor: move;
    position: absolute;
    font-size: 80%;
    border: 1px dashed #000;
}

/* MySQL Parser */
.syntax {
    font-family: Verdana, 'Segoe UI', Arial, Tahoma;
    font-size: 110%;
}

.syntax a {
    text-decoration: none;
    border-bottom: 1px dotted #000;
}

.syntax_comment {
    padding-left: 4pt;
    padding-right: 4pt;
}

.syntax_digit {
}

.syntax_digit_hex {
}

.syntax_digit_integer {
}

.syntax_digit_float {
}

.syntax_punct {
}

.syntax_alpha {
}

.syntax_alpha_columnType {
    text-transform: uppercase;
}

.syntax_alpha_columnAttrib {
    text-transform: uppercase;
}

.syntax_alpha_reservedWord {
    text-transform: uppercase;
    font-weight: bold;
}

.syntax_alpha_functionName {
    text-transform: uppercase;
}

.syntax_alpha_identifier {
}

.syntax_alpha_charset {
}

.syntax_alpha_variable {
}

.syntax_quote {
    white-space: pre;
}

.syntax_quote_backtick {
}

/* no extra space in table cells */
td .icon {
    margin: 0;
}

.selectallarrow {
    margin-right: .3em;
    margin-left: .6em;
}

/* message boxes: error, confirmation */
#pma_errors {
    padding: 0 0.5em;
}

.success h1,
.notice h1,
div.error h1 {
    border-bottom: 2px solid;
    font-weight: bold;
    text-align: left;
    margin: 0 0 .2em 0;
}

div.success,
div.notice,
div.error {
    margin: .5em 0 1.3em;
    border: 1px solid;
    background-repeat: no-repeat;
            background-position: 10px 50%;
    padding: 10px 10px 10px 10px;
        
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
    border-radius: 5px;

    -moz-box-shadow: 0 1px 1px #fff inset;
    -webkit-box-shadow: 0 1px 1px #fff inset;
    box-shadow: 0 1px 1px #fff inset;
}

.success a,
.notice a,
.error a {
    text-decoration: underline;
}

.success {
    color: #000;
    background-color: #ebf8a4;
}

h1.success,
div.success {
    border-color: #a2d246;    
}
.success h1 {
    border-color: #00FF00;
}

.notice {
    color: #000;
    background-color: #e8eef1;
}

h1.notice,
div.notice {
    border-color: #3a6c7e;
}

.notice h1 {
    border-color: #ffb10a;
}

.error {
    border: 1px solid maroon !important;
    color: #000;
    background: pink;
}

h1.error,
div.error {
    border-color: #333; 
}

div.error h1 {
    border-color: #ff0000;
}

.confirmation {
    color: #000;
    background-color: pink;
}

fieldset.confirmation {
}

fieldset.confirmation legend {
}

/* end messageboxes */

.tblcomment {
    font-size: 70%;
    font-weight: normal;
    color: #000099;
}

.tblHeaders {
    font-weight: bold;
    color: #000;
    background: #D3DCE3;
}

div.tools,
.tblFooters {
    font-weight: normal;
    color: #000;
    background: #D3DCE3;
}

.tblHeaders a:link,
.tblHeaders a:active,
.tblHeaders a:visited,
div.tools a:link,
div.tools a:visited,
div.tools a:active,
.tblFooters a:link,
.tblFooters a:active,
.tblFooters a:visited {
    color: #0000FF;
}

.tblHeaders a:hover,
div.tools a:hover,
.tblFooters a:hover {
    color: #FF0000;
}

/* forbidden, no privileges */
.noPrivileges {
    color: #FF0000;
    font-weight: bold;
}

/* disabled text */
.disabled,
.disabled a:link,
.disabled a:active,
.disabled a:visited {
    color: #666;
}

.disabled a:hover {
    color: #666;
    text-decoration: none;
}

tr.disabled td,
td.disabled {
    background-color: #f3f3f3;
    color: #aaa;
}

.nowrap {
    white-space: nowrap;
}

/**
 * login form
 */
body#loginform h1,
body#loginform a.logo {
    display: block;
    text-align: center;
}

body#loginform {
    margin-top: 1em;
    text-align: center;
}

body#loginform div.container {
    text-align: left;
    width: 30em;
    margin: 0 auto;
}

form.login label {
    float: left;
    width: 10em;
    font-weight: bolder;
}

.commented_column {
    border-bottom: 1px dashed #000;
}

.column_attribute {
    font-size: 70%;
}

/******************************************************************************/
/* specific elements */

/* topmenu */
#topmenu a {
    text-shadow: 0 1px 0 #fff;
}

#topmenu .error {
    background: #eee;border: 0 !important;color: #aaa;
}

ul#topmenu,
ul#topmenu2,
ul.tabs {
    font-weight: bold;
    list-style-type: none;
    margin: 0;
    padding: 0;

}

ul#topmenu2 {
    margin: .25em .5em 0;
    height: 2em;
    clear: both;
}

ul#topmenu li,
ul#topmenu2 li {
    float: left;
    margin: 0;
    vertical-align: middle;
}

#topmenu img,
#topmenu2 img {
    margin-right: .5em;
    vertical-align: -3px;
}

.menucontainer {
    background-image: url(./themes/svg_gradient.php?from=ffffff&to=dcdcdc);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#dcdcdc));
background: -webkit-linear-gradient(top, #ffffff, #dcdcdc);
background: -moz-linear-gradient(top, #ffffff, #dcdcdc);
background: -ms-linear-gradient(top, #ffffff, #dcdcdc);
background: -o-linear-gradient(top, #ffffff, #dcdcdc);    border-top: 1px solid #aaa;
}

/* default tab styles */
.tabactive {
    background: #fff !important;
}

ul#topmenu2 a {
    display: block;
    margin: 7px 6px 7px;
    margin-left: 0;
    padding: 4px 10px;
    white-space: nowrap;
    border: 1px solid #ddd;
    border-radius: 20px;
    -moz-border-radius: 20px;
    -webkit-border-radius: 20px;
    background: #f2f2f2;

}

fieldset.caution a {
    color: #FF0000;
}
fieldset.caution a:hover {
    color: #fff;
    background-color: #FF0000;
}

#topmenu {
    margin-top: .5em;
    padding: .1em .3em;
}

ul#topmenu ul {
    -moz-box-shadow: 1px 1px 6px #ddd;
    -webkit-box-shadow: 2px 2px 3px #666;
    box-shadow: 2px 2px 3px #666;
}

ul#topmenu ul.only {
    left: 0;
}

ul#topmenu > li {
    border-right: 1px solid #fff;
    border-left: 1px solid #ccc;
}

/* default tab styles */
ul#topmenu a,
ul#topmenu span {
    padding: .6em;
}

ul#topmenu ul a {
    border-width: 1pt 0 0 0;
    -moz-border-radius: 0;
    -webkit-border-radius: 0;
    border-radius: 0;
}

ul#topmenu ul li:first-child a {
    border-width: 0;
}

/* enabled hover/active tabs */
ul#topmenu > li > a:hover,
ul#topmenu > li > .tabactive {
    text-decoration: none;
}

ul#topmenu ul a:hover,
ul#topmenu ul .tabactive {
    text-decoration: none;
}

ul#topmenu a.tab:hover,
ul#topmenu .tabactive {
    /* background-color: #F5F5F5;  */
}

ul#topmenu2 a.tab:hover,
ul#topmenu2 a.tabactive {
    background-color: #E5E5E5;
    border-radius: .3em;
    -moz-border-radius: .3em;
    -webkit-border-radius: .3em;
    text-decoration: none;
}

/* to be able to cancel the bottom border, use <li class="active"> */
ul#topmenu > li.active {
    /* border-bottom: 0pt solid #F5F5F5; */
    border-right: 0;
}
/* end topmenu */

/* zoom search */
div#dataDisplay input,
div#dataDisplay select {
    margin: 0;
    margin-right: .5em;
}
div#dataDisplay th {
    line-height: 2em;
}

/* Calendar */
table.calendar {
    width: 100%;
}
table.calendar td {
    text-align: center;
}
table.calendar td a {
    display: block;
}

table.calendar td a:hover {
    background-color: #CCFFCC;
}

table.calendar th {
    background-color: #D3DCE3;
}

table.calendar td.selected {
    background-color: #FFCC99;
}

img.calendar {
    border: none;
}
form.clock {
    text-align: center;
}
/* end Calendar */


/* table stats */
div#tablestatistics table {
    float: left;
    margin-bottom: .5em;
    margin-right: 1.5em;
    margin-top: .5em;
    min-width: 16em;
}

/* END table stats */


/* server privileges */
#tableuserrights td,
#tablespecificuserrights td,
#tabledatabases td {
    vertical-align: middle;
}
/* END server privileges */


/* Heading */
#topmenucontainer {
    padding-right: 1em;
    width: 100%;
}

#serverinfo {
    border-bottom: 1px solid #fff;
    background: #888;
    padding: .3em .9em;
    padding-left: 2.2em;
    text-shadow: 0 1px 0 #000;
    width: 10000px;
    overflow: hidden;
}

#serverinfo .item {
    white-space: nowrap;
    color: #fff;
    float: left}

#goto_pagetop {
    position: fixed;
    padding: .25em .25em .2em;
    top: 0;
    right: 0;
    z-index: 900;
    background: #888;
}

#span_table_comment {
    font-weight: normal;
    font-style: italic;
    white-space: nowrap;
}

#serverinfo img {
    margin: 0 .1em 0;
    margin-left: .2em;
}


#textSQLDUMP {
    width: 95%;
    height: 95%;
    font-family: Consolas, "Courier New", Courier, mono;
    font-size: 110%;
}

#TooltipContainer {
    position: absolute;
    z-index: 99;
    width: 20em;
    height: auto;
    overflow: visible;
    visibility: hidden;
    background-color: #ffffcc;
    color: #006600;
    border: .1em solid #000;
    padding: .5em;
}

/* user privileges */
#fieldset_add_user_login div.item {
    border-bottom: 1px solid silver;
    padding-bottom: .3em;
    margin-bottom: .3em;
}

#fieldset_add_user_login label {
    float: left;
    display: block;
    width: 10em;
    max-width: 100%;
    text-align: right;
    padding-right: .5em;
}

#fieldset_add_user_login span.options #select_pred_username,
#fieldset_add_user_login span.options #select_pred_hostname,
#fieldset_add_user_login span.options #select_pred_password {
    width: 100%;
    max-width: 100%;
}

#fieldset_add_user_login span.options {
    float: left;
    display: block;
    width: 12em;
    max-width: 100%;
    padding-right: .5em;
}

#fieldset_add_user_login input {
    width: 12em;
    clear: right;
    max-width: 100%;
}

#fieldset_add_user_login span.options input {
    width: auto;
}

#fieldset_user_priv div.item {
    float: left;
    width: 9em;
    max-width: 100%;
}

#fieldset_user_priv div.item div.item {
    float: none;
}

#fieldset_user_priv div.item label {
    white-space: nowrap;
}

#fieldset_user_priv div.item select {
    width: 100%;
}

#fieldset_user_global_rights fieldset {
    float: left;
}
/* END user privileges */


/* serverstatus */

.linkElem:hover {
    text-decoration: underline;
    color: #235a81;
    cursor: pointer;
}

h3#serverstatusqueries span {
    font-size: 60%;
    display: inline;
}

img.sortableIcon {
    float: right;
    background-repeat: no-repeat;
    margin: 0;
}

.buttonlinks {
    float: right;
    white-space: nowrap;
}

/* Also used for the variables page */
fieldset#tableFilter {
    margin-bottom: 1em;
}

div#serverStatusTabs {
    margin-top: 1em;
}

caption a.top {
    float: right;
}

div#serverstatusquerieschart {
    float: left;
    width: 500px;
    height: 350px;
    padding-left: 30px;
}

table#serverstatusqueriesdetails,
table#serverstatustraffic {
    float: left;
}

table#serverstatusqueriesdetails th {
    min-width: 35px;
}

table#serverstatusvariables {
    width: 100%;
    margin-bottom: 1em;
}
table#serverstatusvariables .name {
    width: 18em;
    white-space: nowrap;
}
table#serverstatusvariables .value {
    width: 6em;
}
table#serverstatusconnections {
    float: left;
    margin-left: 30px;
}

div#serverstatus table tbody td.descr a,
div#serverstatus table .tblFooters a {
    white-space: nowrap;
}

div.liveChart {
    clear: both;
    min-width: 500px;
    height: 400px;
    padding-bottom: 80px;
}

#addChartDialog input[type="text"] {
    margin: 0;
    padding: 3px;
}

div#chartVariableSettings {
    border: 1px solid #ddd;
    background-color: #E6E6E6;
    margin-left: 10px;
}

table#chartGrid div.monitorChart {
    background: #EBEBEB;
}

div#serverstatus div.tabLinks {
    float: left;
    padding-bottom: 10px;
}

.popupContent {
    display: none;
    position: absolute;
    border: 1px solid #CCC;
    margin: 0;
    padding: 3px;
    -moz-box-shadow: 2px 2px 3px #666;
    -webkit-box-shadow: 2px 2px 3px #666;
    box-shadow: 2px 2px 3px #666;
    background-color: #fff;
    z-index: 2;
}

div#logTable {
    padding-top: 10px;
    clear: both;
}

div#logTable table {
    width: 100%;
}

div#queryAnalyzerDialog {
    min-width: 700px;
}

div#queryAnalyzerDialog div.CodeMirror-scroll {
    height: auto;
}

div#queryAnalyzerDialog div#queryProfiling {
    height: 300px;
}

div#queryAnalyzerDialog td.explain {
    width: 250px;
}

div#queryAnalyzerDialog table.queryNums {
    display: none;
    border: 0;
    text-align: left;
}

.smallIndent {
    padding-left: 7px;
}

/* end serverstatus */

/* server variables */
#serverVariables {
    min-width: 30em;
}
#serverVariables .var-row > div {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    line-height: 2em;
}
#serverVariables .var-header {
    color: #000;
    background: #f3f3f3;
    background-image: url(./themes/svg_gradient.php?from=ffffff&to=cccccc);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#cccccc));
background: -webkit-linear-gradient(top, #ffffff, #cccccc);
background: -moz-linear-gradient(top, #ffffff, #cccccc);
background: -ms-linear-gradient(top, #ffffff, #cccccc);
background: -o-linear-gradient(top, #ffffff, #cccccc);    font-weight: bold;
}
#serverVariables .var-header .var-value {
    text-align: left;
}
#serverVariables .var-row {
    padding: 0.5em;
    min-height: 18px;
}
#serverVariables .var-name {
    width: 45%;
    float: left;
    font-weight: bold;
}
#serverVariables .var-name.session {
    font-weight: normal;
    font-style: italic;
}
#serverVariables .var-value {
    width: 50%;
    float: right;
    text-align: right;
}
#serverVariables .var-doc {
    overflow:visible;
    float: right;
}

/* server variables editor */
#serverVariables .editLink {
    padding-right: 1em;
    float: left;
    font-family: sans-serif;
}
#serverVariables .serverVariableEditor {
    width: 100%;
    overflow: hidden;
}
#serverVariables .serverVariableEditor input {
    width: 100%;
    margin: 0 0.5em;
    box-sizing: border-box;
    -ms-box-sizing: border-box;
    -moz-box-sizing: border-box;
    -webkit-box-sizing: border-box;
    height: 2.2em;
}
#serverVariables .serverVariableEditor div {
    display: block;
    overflow: hidden;
    padding-right: 1em;
}
#serverVariables .serverVariableEditor a {
    float: right;
    margin: 0 0.5em;
    line-height: 2em;
}
/* end server variables */


p.notice {
    margin: 1.5em 0;
    border: 1px solid #000;
    background-repeat: no-repeat;
            background-position: 10px 50%;
    padding: 10px 10px 10px 25px;
            -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
    border-radius: 5px;
    -moz-box-shadow: 0 1px 2px #fff inset;
    -webkit-box-shadow: 0 1px 2px #fff inset;
    box-shadow: 0 1px 2px #fff; inset;
    background: #555;
    color: #d4fb6a;
}

p.notice a {
    color: #fff;
    text-decoration: underline;
}

/* querywindow */
body#bodyquerywindow {
    margin: 0;
    padding: 0;
    background-image: none;
    background-color: #F5F5F5;
}

div#querywindowcontainer {
    margin: 0;
    padding: 0;
    width: 100%;
}

div#querywindowcontainer fieldset {
    margin-top: 0;
}
/* END querywindow */

/* profiling */

div#profilingchart {
    width: 550px;
    height: 370px;
    float: left;
}

/* END profiling */

/* table charting */

#resizer {
    border: 1px solid silver;
}
#inner-resizer { /* make room for the resize handle */
    padding: 10px;
}

/* END table charting */

/* querybox */

#togglequerybox {
    margin: 0 10px;
}

#serverstatus h3
{
    margin: 15px 0;
    font-weight: normal;
    color: #999;
    font-size: 1.7em;
}
#sectionlinks {
    padding: 16px;
    background: #f3f3f3;
    border: 1px solid #aaa;
    border-radius: 5px;
    -webkit-border-radius: 5px;
    -moz-border-radius: 5px;
    box-shadow: 0 1px 1px #fff inset;
    -webkit-box-shadow: 0 1px 1px #fff inset;
    -moz-box-shadow: 0 1px 1px #fff inset;
}
#sectionlinks a,
.buttonlinks a,
a.button {
    font-size: .88em;
    font-weight: bold;
    text-shadow: 0 1px 0 #fff;
    line-height: 35px;
    margin-left: 7px;
    border: 1px solid #aaa;
    padding: 5px 10px;
    color: #111;
    text-decoration: none;
    background: #ddd;
    white-space: nowrap;
    border-radius: 20px;
    -webkit-border-radius: 20px;
    -moz-border-radius: 20px;
    box-shadow: 1px 1px 2px rgba(0,0,0,.5);
    /*
    -webkit-box-shadow: 1px 1px 2px rgba(0,0,0,.5);
    -moz-box-shadow: 1px 1px 2px rgba(0,0,0,.5);
    text-shadow: #fff 0 1px 0;
    */
    background-image: url(./themes/svg_gradient.php?from=ffffff&to=cccccc);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#cccccc));
background: -webkit-linear-gradient(top, #ffffff, #cccccc);
background: -moz-linear-gradient(top, #ffffff, #cccccc);
background: -ms-linear-gradient(top, #ffffff, #cccccc);
background: -o-linear-gradient(top, #ffffff, #cccccc);}
#sectionlinks a:hover,
.buttonlinks a:hover,
a.button:hover {
    background-image: url(./themes/svg_gradient.php?from=cccccc&to=dddddd);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#cccccc), to(#dddddd));
background: -webkit-linear-gradient(top, #cccccc, #dddddd);
background: -moz-linear-gradient(top, #cccccc, #dddddd);
background: -ms-linear-gradient(top, #cccccc, #dddddd);
background: -o-linear-gradient(top, #cccccc, #dddddd);}

div#sqlquerycontainer {
    float: left;
    width: 69%;
    /* height: 15em; */
}

div#tablefieldscontainer {
    float: right;
    width: 29%;
    /* height: 15em; */
}

div#tablefieldscontainer select {
    width: 100%;
    background: #fff;
    /* height: 12em; */
}

textarea#sqlquery {
    width: 100%;
    /* height: 100%; */
    -moz-border-radius: 4px;
    -webkit-border-radius: 4px;
    border-radius: 4px;
    border: 1px solid #aaa;
    padding: 5px;
    font-family: inherit;
}
textarea#sql_query_edit {
    height: 7em;
    width: 95%;
    display: block;
}
div#queryboxcontainer div#bookmarkoptions {
    margin-top: .5em;
}
/* end querybox */

/* main page */
#maincontainer {
    /* background-image: url(./themes/pmahomme/img/logo_right.png); */
    /* background-position: right bottom; */
    /* background-repeat: no-repeat; */
}

#mysqlmaininformation,
#pmamaininformation {
    float: left;
    width: 49%;
}

#maincontainer ul {
    list-style-type: disc;
    vertical-align: middle;
}

#maincontainer li {
    margin-bottom: .3em;
}
/* END main page */


/* iconic view for ul items */

li.no_bullets {
    list-style-type:none !important;    
    margin-left: -25px !important;      //align with other list items which have bullets
}

/* END iconic view for ul items */

#body_browse_foreigners {
    background: #f3f3f3;
    margin: .5em .5em 0 .5em;
}

#bodyquerywindow {
    background: #f3f3f3;
}

#bodythemes {
    width: 500px;
    margin: auto;
    text-align: center;
}

#bodythemes img {
    border: .1em solid #000;
}

#bodythemes a:hover img {
    border: .1em solid red;
}

#fieldset_select_fields {
    float: left;
}

#selflink {
    clear: both;
    display: block;
    margin-top: 1em;
    margin-bottom: 1em;
    width: 98%;
    margin-left: 1%;
    border-top: .1em solid silver;
    text-align: right;
}

#table_innodb_bufferpool_usage,
#table_innodb_bufferpool_activity {
    float: left;
}

#div_mysql_charset_collations table {
    float: left;
}

.operations_half_width {
    width: 48%;
    float: left;
}

.operations_full_width {
    width: 100%;
    clear: both;
}

#qbe_div_table_list {
    float: left;
}

#qbe_div_sql_query {
    float: left;
}

label.desc {
    width: 30em;
    float: left;
}

label.desc sup {
    position: absolute;
}

code.sql,
div.sqlvalidate {
    display: block;
    padding: 1em;
    margin-top: 0;
    margin-bottom: 0;
    max-height: 10em;
    overflow: auto;
    background: #E5E5E5;
}

#main_pane_left {
    width: 60%;
    float: left;
    padding-top: 1em;
}

#main_pane_right {
    margin-left: 60%;
    padding-top: 1em;
    padding-left: 1em;
}

.group {

    border: 1px solid #999;
    background: #f3f3f3;
    -moz-border-radius: 4px;
    -webkit-border-radius: 4px;
    border-radius: 4px;
    -moz-box-shadow: 2px 2px 5px #ccc;
    -webkit-box-shadow: 2px 2px 5px #ccc;
    box-shadow: 2px 2px 5px #ccc;
    margin-bottom: 1em;
    padding-bottom: 1em;
}

.group h2 {
    background-color: #bbb;
    padding: .1em .3em;
    margin-top: 0;
    color: #fff;
    font-size: 1.6em;
    font-weight: normal;
    text-shadow: 0 1px 0 #777;
    -moz-box-shadow: 1px 1px 15px #999 inset;
    -webkit-box-shadow: 1px 1px 15px #999 inset;
    box-shadow: 1px 1px 15px #999 inset;
}

.group-cnt {
    padding: 0;
    padding-left: .5em;
    display: inline-block;
    width: 98%;
}

textarea#partitiondefinition {
    height: 3em;
}


/* for elements that should be revealed only via js */
.hide {
    display: none;
}

#list_server {
    list-style-image: none;
}

/**
  *  Progress bar styles
  */
div.upload_progress
{
    width: 400px;
    margin: 3em auto;
    text-align: center;
}

div.upload_progress_bar_outer
{
    border: 1px solid #000;
    width: 202px;
    position: relative;
    margin: 0 auto 1em;
    color: #000;
}

div.upload_progress_bar_inner
{
    background-color: #ddd;
    width: 0;
    height: 12px;
    margin: 1px;
    overflow: hidden;
    color: #000;
    position: relative;
}

div.upload_progress_bar_outer div.percentage
{
    position: absolute;
    top: 0;
    left: 0;
    width: 202px;
}

div.upload_progress_bar_inner div.percentage
{
    top: -1px;
    left: -1px;
}

div#statustext {
    margin-top: .5em;
}

table#serverconnection_src_remote,
table#serverconnection_trg_remote,
table#serverconnection_src_local,
table#serverconnection_trg_local  {
  float: left;
}
/**
  *  Validation error message styles
  */
input[type=text].invalid_value,
.invalid_value {
    background: #FFCCCC;
}

/**
  *  Ajax notification styling
  */
 .ajax_notification {
    top: 0;           /** The notification needs to be shown on the top of the page */
    position: fixed;
    margin-top: 0;
    margin-right: auto;
    margin-bottom: 0;
    margin-left: auto;
    padding: 5px;   /** Keep a little space on the sides of the text */
    width: 350px;

    z-index: 1100;      /** If this is not kept at a high z-index, the jQueryUI modal dialogs (z-index: 1000) might hide this */
    text-align: center;
    display: inline;
    left: 0;
    right: 0;
    background-image: url(./themes/pmahomme/img/ajax_clock_small.gif);
    background-repeat: no-repeat;
    background-position: 2%;
    border: 1px solid #e2b709;
 }

/* additional styles */
.ajax_notification {
    margin-top: 200px;
    background: #ffe57e;
    border-radius: 5px;
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
    box-shadow: 0 5px 90px #888;
    -moz-box-shadow: 0 5px 90px #888;
    -webkit-box-shadow: 0 5px 90px #888;
}

#loading_parent {
    /** Need this parent to properly center the notification division */
    position: relative;
    width: 100%;
 }
/**
  * Export and Import styles
  */

.exportoptions h3,
.importoptions h3 {
    border-bottom: 1px #999 solid;
    font-size: 110%;
}

.exportoptions ul,
.importoptions ul,
.format_specific_options ul {
    list-style-type: none;
    margin-bottom: 15px;
}

.exportoptions li,
.importoptions li {
    margin: 7px;
}
.exportoptions label,
.importoptions label,
.exportoptions p,
.importoptions p {
    margin: 5px;
    float: none;
}

#csv_options label.desc,
#ldi_options label.desc,
#latex_options label.desc,
#output label.desc {
    float: left;
    width: 15em;
}

.exportoptions,
.importoptions {
    margin: 20px 30px 30px;
    margin-left: 10px;
}

.exportoptions #buttonGo,
.importoptions #buttonGo {
    font-weight: bold;
    margin-left: 14px;
    border: 1px solid #aaa;
    padding: 5px 12px;
    color: #111;
    text-decoration: none;
    background: #ddd;

    border-radius: 12px;
    -webkit-border-radius: 12px;
    -moz-border-radius: 12px;

    text-shadow: 0 1px 0 #fff;

    background-image: url(./themes/svg_gradient.php?from=ffffff&to=cccccc);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#cccccc));
background: -webkit-linear-gradient(top, #ffffff, #cccccc);
background: -moz-linear-gradient(top, #ffffff, #cccccc);
background: -ms-linear-gradient(top, #ffffff, #cccccc);
background: -o-linear-gradient(top, #ffffff, #cccccc);    cursor: pointer;
}
#buttonGo:hover {
    background-image: url(./themes/svg_gradient.php?from=cccccc&to=dddddd);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#cccccc), to(#dddddd));
background: -webkit-linear-gradient(top, #cccccc, #dddddd);
background: -moz-linear-gradient(top, #cccccc, #dddddd);
background: -ms-linear-gradient(top, #cccccc, #dddddd);
background: -o-linear-gradient(top, #cccccc, #dddddd);}

.format_specific_options h3 {
    margin: 10px 0 0;
    margin-left: 10px;
    border: 0;
}

.format_specific_options {
    border: 1px solid #999;
    margin: 7px 0;
    padding: 3px;
}

p.desc {
    margin: 5px;
}

/**
  * Export styles only
  */
select#db_select,
select#table_select {
    width: 400px;
}

.export_sub_options {
    margin: 20px 0 0;
    margin-left: 30px;
}

.export_sub_options h4 {
    border-bottom: 1px #999 solid;
}

.export_sub_options li.subgroup {
    display: inline-block;
    margin-top: 0;
}

.export_sub_options li {
    margin-bottom: 0;
}

#quick_or_custom,
#output_quick_export {
    display: none;
}
/**
 * Import styles only
 */

.importoptions #import_notification {
    margin: 10px 0;
    font-style: italic;
}

input#input_import_file {
    margin: 5px;
}

.formelementrow {
    margin: 5px 0 5px 0;
}

#popup_background {
    display: none;
    position: fixed;
    _position: absolute; /* hack for IE6 */
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
    background: #000;
    z-index: 1000;
    overflow: hidden;
}

/**
 * Table structure styles
 */
#fieldsForm ul.table-structure-actions {
    margin: 0;
    padding: 0;
    list-style: none;
}
#fieldsForm ul.table-structure-actions li {
    float: left;
    margin-right: 0.3em; /* same as padding of "table td" */
}
#fieldsForm ul.table-structure-actions .submenu li {
    padding: 0;
    margin: 0;
}
#fieldsForm ul.table-structure-actions .submenu li span {
    padding: 0.3em;
    margin: 0.1em;
}
/**
 * Indexes
 */
#index_frm .index_info input,
#index_frm .index_info select {
    width: 14em;
    box-sizing: border-box;
    -ms-box-sizing: border-box;
    -moz-box-sizing: border-box;
    -webkit-box-sizing: border-box;
}

#index_frm .index_info div {
    padding: .2em 0;
}

#index_frm .index_info .label {
    float: left;
    min-width: 12em;
}

#index_frm .slider {
    width: 10em;
    margin: .6em;
    float: left;
}

#index_frm .add_fields {
    float: left;
}

#index_frm .add_fields input {
    margin-left: 1em;
}

#index_frm input {
    margin: 0;
}

#index_frm td {
    vertical-align: middle;
}

table#index_columns {
    width: 100%;
}

table#index_columns select {
    width: 100%;
}

#move_columns_dialog div {
    padding: 1em;
}

#move_columns_dialog ul {
    list-style: none;
    margin: 0;
    padding: 0;
}

#move_columns_dialog li {
    background: #D3DCE3;
    border: 1px solid #aaa;
    color: #000;
    font-weight: bold;
    margin: .4em;
    padding: .2em;
    -webkit-border-radius: 2px;
    -moz-border-radius: 2px;
    border-radius: 2px;
}

.margin#change_column_dialog {
    margin: 0 .5em;
}

/* config forms */
.config-form ul.tabs {
    margin: 1.1em .2em 0;
    padding: 0 0 .3em 0;
    list-style: none;
    font-weight: bold;
}

.config-form ul.tabs li {
    float: left;
    margin-bottom: -1px;
}

.config-form ul.tabs li a {
    display: block;
    margin: .1em .2em 0;
    white-space: nowrap;
    text-decoration: none;
    border: 1px solid #D5D5D5;
    border-bottom: 1px solid #aaa;
}

.config-form ul.tabs li a {
    padding: 7px 10px;
    -webkit-border-radius: 5px 5px 0 0;
    -moz-border-radius: 5px 5px 0 0;
    border-radius: 5px 5px 0 0;
    background: #f2f2f2;
    color: #555;
    text-shadow: 0 1px 0 #fff;
}

.config-form ul.tabs li a:hover,
.config-form ul.tabs li a:active {
    background: #e5e5e5;
}

.config-form ul.tabs li.active a {
    background-color: #fff;
    margin-top: 1px;
    color: #000;
    text-shadow: none;
    border-color: #aaa;
    border-bottom: 1px solid #fff;
}

.config-form fieldset {
    margin-top: 0;
    padding: 0;
    clear: both;
    -webkit-border-radius: 0;
    -moz-border-radius: 0;
    border-radius: 0;
}

.config-form legend {
    display: none;
}

.config-form fieldset p {
    margin: 0;
    padding: .5em;
    background: #fff;
    border-top: 0;
}

.config-form fieldset .errors { /* form error list */
    margin: 0 -2px 1em;
    padding: .5em 1.5em;
    background: #FBEAD9;
    border: 0 #C83838 solid;
    border-width: 1px 0;
    list-style: none;
    font-family: sans-serif;
    font-size: small;
}

.config-form fieldset .inline_errors { /* field error list */
    margin: .3em .3em .3em;
    margin-left: 0;
    padding: 0;
    list-style: none;
    color: #9A0000;
    font-size: small;
}

.config-form fieldset th {
    padding: .3em .3em .3em;
    padding-left: .5em;
    text-align: left;
    vertical-align: top;
    width: 40%;
    background: transparent;
    filter: none;
}

.config-form fieldset .doc,
.config-form fieldset .disabled-notice {
    margin-left: 1em;
}

.config-form fieldset .disabled-notice {
    font-size: 80%;
    text-transform: uppercase;
    color: #E00;
    cursor: help;
}

.config-form fieldset td {
    padding-top: .3em;
    padding-bottom: .3em;
    vertical-align: top;
}

.config-form fieldset th small {
    display: block;
    font-weight: normal;
    font-family: sans-serif;
    font-size: x-small;
    color: #444;
}

.config-form fieldset th,
.config-form fieldset td {
    border-top: 1px #D5D5D5 solid;
    border-right: none;
}

fieldset .group-header th {
    background: #D5D5D5;
}

fieldset .group-header + tr th {
    padding-top: .6em;
}

fieldset .group-field-1 th,
fieldset .group-header-2 th {
    padding-left: 1.5em;
}

fieldset .group-field-2 th,
fieldset .group-header-3 th {
    padding-left: 3em;
}

fieldset .group-field-3 th {
    padding-left: 4.5em;
}

fieldset .disabled-field th,
fieldset .disabled-field th small,
fieldset .disabled-field td {
    color: #666;
    background-color: #ddd;
}

.config-form .lastrow {
    border-top: 1px #000 solid;
}

.config-form .lastrow {
    background: #D3DCE3;;
    padding: .5em;
    text-align: center;
}

.config-form .lastrow input {
    font-weight: bold;
}

/* form elements */

.config-form span.checkbox {
    padding: 2px;
    display: inline-block;
}

.config-form .custom { /* customized field */
    background: #FFC;
}

.config-form span.checkbox.custom {
    padding: 1px;
    border: 1px #EDEC90 solid;
    background: #FFC;
}

.config-form .field-error {
    border-color: #A11 !important;
}

.config-form input[type="text"],
.config-form select,
.config-form textarea {
    border: 1px #A7A6AA solid;
    height: auto;
}

.config-form input[type="text"]:focus,
.config-form select:focus,
.config-form textarea:focus {
    border: 1px #6676FF solid;
    background: #F7FBFF;
}

.config-form .field-comment-mark {
    font-family: serif;
    color: #007;
    cursor: help;
    padding: 0 .2em;
    font-weight: bold;
    font-style: italic;
}

.config-form .field-comment-warning {
    color: #A00;
}

/* error list */
.config-form dd {
    margin-left: .5em;
}

.config-form dd:before {
    content: "\25B8  ";
}

.click-hide-message {
    cursor: pointer;
}

.prefsmanage_opts {
    margin-left: 2em;
}

#prefs_autoload {
    margin-bottom: .5em;
}

#placeholder .button {
    position: absolute;
    cursor: pointer;
}

#placeholder div.button {
    font-size: smaller;
    color: #999;
    background-color: #eee;
    padding: 2px;
}

.wrapper {
    float: left;
    margin-bottom: 1.5em;
}
.toggleButton {
    position: relative;
    cursor: pointer;
    font-size: .8em;
    text-align: center;
    line-height: 1.4em;
    height: 1.55em;
    overflow: hidden;
    border-right: .1em solid #888;
    border-left: .1em solid #888;
    -webkit-border-radius: .3em;
    -moz-border-radius: .3em;
    border-radius: .3em;
}
.toggleButton table,
.toggleButton td,
.toggleButton img {
    padding: 0;
    position: relative;
}
.toggleButton .container {
    position: absolute;
}
.toggleButton .toggleOn {
    color: #fff;
    padding: 0 1em;
    text-shadow: 0 0 .2em #000;
}
.toggleButton .toggleOff {
    padding: 0 1em;
}

.doubleFieldset fieldset {
    width: 48%;
    float: left;
    padding: 0;
}
.doubleFieldset fieldset.left {
    margin-right: 1%;
}
.doubleFieldset fieldset.right {
    margin-left: 1%;
}
.doubleFieldset legend {
    margin-left: 1.5em;
}
.doubleFieldset div.wrap {
    padding: 1.5em;
}

#table_columns input[type="text"],
#table_columns select {
    width: 10em;
    box-sizing: border-box;
    -ms-box-sizing: border-box;
    -moz-box-sizing: border-box;
    -webkit-box-sizing: border-box;
}

#table_columns select {
    margin: 0 6px;
}

#placeholder {
    position: relative;
    border: 1px solid #aaa;
    float: right;
    overflow: hidden;
}

.placeholderDrag {
    cursor: move;
}

#placeholder .button {
    position: absolute;
}

#left_arrow {
    left: 8px;
    top: 26px;
}

#right_arrow {
    left: 26px;
    top: 26px;
}

#up_arrow {
    left: 17px;
    top: 8px;
}

#down_arrow {
    left: 17px;
    top: 44px;
}

#zoom_in {
    left: 17px;
    top: 67px;
}

#zoom_world {
    left: 17px;
    top: 85px;
}

#zoom_out {
    left: 17px;
    top: 103px;
}

.colborder {
    cursor: col-resize;
    height: 100%;
    margin-left: -6px;
    position: absolute;
    width: 5px;
}

.colborder_active {
    border-right: 2px solid #a44;
}

.pma_table td {
    position: static;
}

.pma_table th.draggable span,
.pma_table tbody td span {
    display: block;
    overflow: hidden;
}

.modal-copy input {
    display: block;
    width: 100%;
    margin-top: 1.5em;
    padding: .3em 0;
}

.cRsz {
    position: absolute;
}

.cCpy {
    background: #333;
    color: #FFF;
    font-weight: bold;
    margin: .1em;
    padding: .3em;
    position: absolute;
    text-shadow: -1px -1px #000;

    -moz-box-shadow: 0 0 .7em #000;
    -webkit-box-shadow: 0 0 .7em #000;
    box-shadow: 0 0 .7em #000;
    -moz-border-radius: .3em;
    -webkit-border-radius: .3em;
    border-radius: .3em;
}

.cPointer {
    background: url(./themes/pmahomme/img/col_pointer.png);
    height: 20px;
    margin-left: -5px;  /* must be minus half of its width */
    margin-top: -10px;
    position: absolute;
    width: 10px;
}

.tooltip {
    background: #333 !important;
    opacity: .8 !important;
    border: 1px solid #000 !important;
    -moz-border-radius: .3em !important;
    -webkit-border-radius: .3em !important;
    border-radius: .3em !important;
    text-shadow: -1px -1px #000 !important;
    font-size: .8em !important;
    font-weight: bold !important;
    padding: 1px 3px !important;
}

.tooltip * {
    background: none !important;
    color: #FFF !important;
}

.cDrop {
    left: 0;
    position: absolute;
    top: 0;
}

.coldrop {
    background: url(./themes/pmahomme/img/col_drop.png);
    cursor: pointer;
    height: 16px;
    margin-left: .3em;
    margin-top: .3em;
    position: absolute;
    width: 16px;
}

.coldrop:hover,
.coldrop-hover {
    background-color: #999;
}

.cList {
    background: #EEE;
    border: solid 1px #999;
    position: absolute;
    -moz-box-shadow: 0 .2em .5em #333;
    -webkit-box-shadow: 0 .2em .5em #333;
    box-shadow: 0 .2em .5em #333;
}

.cList .lDiv div {
    padding: .2em .5em .2em;
    padding-left: .2em;
}

.cList .lDiv div:hover {
    background: #DDD;
    cursor: pointer;
}

.cList .lDiv div input {
    cursor: pointer;
}

.showAllColBtn {
    border-bottom: solid 1px #999;
    border-top: solid 1px #999;
    cursor: pointer;
    font-size: .9em;
    font-weight: bold;
    padding: .35em 1em;
    text-align: center;
}

.showAllColBtn:hover {
    background: #DDD;
}

#page_content {
    background-color: white;
}

.navigation {
    margin: .8em 0;

    border-radius: 5px;
    -webkit-border-radius: 5px;
    -moz-border-radius: 5px;

    background-image: url(./themes/svg_gradient.php?from=eeeeee&to=cccccc);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#eeeeee), to(#cccccc));
background: -webkit-linear-gradient(top, #eeeeee, #cccccc);
background: -moz-linear-gradient(top, #eeeeee, #cccccc);
background: -ms-linear-gradient(top, #eeeeee, #cccccc);
background: -o-linear-gradient(top, #eeeeee, #cccccc);}

.navigation td {
    margin: 0;
    padding: 0;
    vertical-align: middle;
    white-space: nowrap;
}

.navigation_separator {
    color: #999;
    display: inline-block;
    font-size: 1.5em;
    text-align: center;
    height: 1.4em;
    width: 1.2em;
    text-shadow: 1px 0 #FFF;
}

.navigation input[type=submit] {
    background: none;
    border: 0;
    filter: none;
    margin: 0;
    padding: .8em .5em;

    border-radius: 0;
    -webkit-border-radius: 0;
    -moz-border-radius: 0;
}

.navigation input[type=submit]:hover,
.navigation input.edit_mode_active {
    color: #fff;
    cursor: pointer;
    text-shadow: none;

    background-image: url(./themes/svg_gradient.php?from=333333&to=555555);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#333333), to(#555555));
background: -webkit-linear-gradient(top, #333333, #555555);
background: -moz-linear-gradient(top, #333333, #555555);
background: -ms-linear-gradient(top, #333333, #555555);
background: -o-linear-gradient(top, #333333, #555555);}

.navigation select {
    margin: 0 .8em;
}

.cEdit {
    margin: 0;
    padding: 0;
    position: absolute;
}

.cEdit input[type=text] {
    background: #FFF;
    height: 100%;
    margin: 0;
    padding: 0;
}

.cEdit .edit_area {
    background: #FFF;
    border: 1px solid #999;
    min-width: 10em;
    padding: .3em .5em;
}

.cEdit .edit_area select,
.cEdit .edit_area textarea {
    width: 97%;
}

.cEdit .cell_edit_hint {
    color: #555;
    font-size: .8em;
    margin: .3em .2em;
}

.cEdit .edit_box {
    overflow: hidden;
    padding: 0;
}

.cEdit .edit_box_posting {
    background: #FFF url(./themes/pmahomme/img/ajax_clock_small.gif) no-repeat right center;
    padding-right: 1.5em;
}

.cEdit .edit_area_loading {
    background: #FFF url(./themes/pmahomme/img/ajax_clock_small.gif) no-repeat center;
    height: 10em;
}

.cEdit .goto_link {
    background: #EEE;
    color: #555;
    padding: .2em .3em;
}

.saving_edited_data {
    background: url(./themes/pmahomme/img/ajax_clock_small.gif) no-repeat left;
    padding-left: 20px;
}

/* css for timepicker */
.ui-timepicker-div .ui-widget-header { margin-bottom: 8px; }
.ui-timepicker-div dl { text-align: left; }
.ui-timepicker-div dl dt { height: 25px; margin-bottom: -25px; }
.ui-timepicker-div dl dd { margin: 0 10px 10px 65px; }
.ui-timepicker-div td { font-size: 90%; }
.ui-tpicker-grid-label { background: none; border: none; margin: 0; padding: 0; }
.ui-timepicker-rtl { direction: rtl; }
.ui-timepicker-rtl dl { text-align: right; }
.ui-timepicker-rtl dl dd { margin: 0 65px 10px 10px; }

input.btn {
    color: #333;
    background-color: #D0DCE0;
}

body .ui-widget {
    font-size: 1em;
}

.ui-dialog fieldset legend a {
    color: #235A81;
}

/* over-riding jqplot-yaxis class */
.jqplot-yaxis {
    left:0px !important;
    min-width:25px;
    width:auto;
}
.jqplot-axis {
    overflow:hidden;
}

/* FILE: enum_editor.css.php */

/**
 * ENUM/SET editor styles
 */
p.enum_notice {
    margin: 5px 2px;
    font-size: 80%;
}

#enum_editor p {
    margin-top: 0;
    font-style: italic;
}

#enum_editor .values,
#enum_editor .add {
    width: 100%;
}

#enum_editor .add td {
    vertical-align: middle;
    width: 50%;
    padding: 0 0 0;
    padding-left: 1em;
}

#enum_editor .values td.drop {
    width: 1.8em;
    cursor: pointer;
    vertical-align: middle;
}

#enum_editor .values input {
    margin: .1em 0;
    padding-right: 2em;
    width: 100%;
}

#enum_editor .values img {
    width: 1.8em;
    vertical-align: middle;
}

#enum_editor input.add_value {
    margin: 0;
    margin-right: 0.4em;
}

#enum_editor_output textarea {
    width: 100%;
    float: right;
    margin: 1em 0 0 0;
}

/**
 * ENUM/SET editor integration for the routines editor
 */
.enum_hint {
    position: relative;
}

.enum_hint a {
    position: absolute;
    left: 81%;
    bottom: .35em;
}

/* FILE: gis.css.php */

.gis_table td {
    vertical-align: middle;
}

.gis_table select {
    min-width: 151px;
    margin: 6px;
}

.gis_table .button {
   text-align: right;
}

/**
 * GIS data editor styles
 */
a.close_gis_editor {
    float: right;
}

#gis_editor {
    display: none;
    position: fixed;
    _position: absolute; /* hack for IE */
    z-index: 1001;
    overflow-y: auto;
    overflow-x: hidden;
}

#gis_data {
    min-height: 230px;
}

#gis_data_textarea {
    height: 6em;
}

#gis_data_editor {
    background: #D0DCE0;
    padding: 15px;
    min-height: 500px;
}

#gis_data_editor .choice {
    display: none;
}

#gis_data_editor input[type="text"] {
    width: 75px;
}

/* FILE: navigation.css.php */

/******************************************************************************/
/* Navigation */

#pma_navigation {
    width: 240px;
    overflow: hidden;
    position: fixed;
    top: 0;
    left: 0;
    height: 100%;
    background: url(./themes/pmahomme/img/left_nav_bg.png) repeat-y right 0% #f3f3f3;
    color: #000;
    z-index: 800;
}

#pma_navigation_content {
    width: 100%;
    height: 100%;
    position: absolute;
    top: 0;
    left: 0;
    z-index: 0;
}

#pma_navigation ul {
    margin: 0;
}

#pma_navigation form {
    margin: 0;
    padding: 0;
    display: inline;
}

#pma_navigation select#select_server,
#pma_navigation select#lightm_db {
    width: 100%;
}

/******************************************************************************/
/* specific elements */

#pma_navigation div.pageselector {
    text-align: center;
    margin: 0;
    margin-left: 0.75em;
    border-left: 1px solid #666;
}

#pma_navigation div#pmalogo {
    }

#pma_navigation #pmalogo,
#pma_navigation #serverChoice,
#pma_navigation #leftframelinks,
#pma_navigation #recentTableList,
#pma_navigation #databaseList,
#pma_navigation div.pageselector.dbselector {
    text-align: center;
    padding: 5px 10px 0px;
    border: 0;
}

#pma_navigation #recentTableList select,
#pma_navigation #serverChoice select
 {
    width: 80%;
}

#pma_navigation_content > img.throbber {
    display: none;
    margin: .3em auto 0;
}

/* Navigation tree*/
#pma_navigation_tree {
    margin: 0;
    margin-left: 10px;
    color: #444;
    height: 74%;
    position: relative;
}
#pma_navigation_tree_content {
    width: 100%;
    overflow: hidden;
    overflow-y: auto;
    position: absolute;
    height: 100%;
}
#pma_navigation_tree a {
    color: #000;
}
#pma_navigation_tree a:hover {
    text-decoration: underline;
}
#pma_navigation_tree li.activePointer {
    color: #000;
    background-color: #ddd;
}
#pma_navigation_tree li.selected {
    color: #000;
    background-color: #ddd;
}
#pma_navigation_tree ul {
    clear: both;
    padding: 0;
    list-style-type: none;
    margin: 0;
}
#pma_navigation_tree ul ul {
    position: relative;
}
#pma_navigation_tree li {
    white-space: nowrap;
    clear: both;
    min-height: 16px;
}
#pma_navigation_tree img {
    margin: 0;
}
#pma_navigation_tree div.block {
    position: relative;
    width: 1.5em;
    height: 1.5em;
    min-width: 16px;
    min-height: 16px;
    float: left;
}
#pma_navigation_tree div.block i,
#pma_navigation_tree div.block b {
    width: 1.5em;
    height: 1.5em;
    min-width: 16px;
    min-height: 8px;
    position: absolute;
    bottom: 0.7em;
    left: 0.75em;
    z-index: 0;
}
#pma_navigation_tree div.block i { /* Top and right segments for the tree element connections */
    display: block;
    border-left: 1px solid #666;
    border-bottom: 1px solid #666;
}
#pma_navigation_tree div.block i.first { /* Removes top segment */
    border-left: 0;
}
#pma_navigation_tree div.block b { /* Bottom segment for the tree element connections */
    display: block;
    height: 0.75em;
    bottom: 0;
    left: 0.75em;
    border-left: 1px solid #666;
}
#pma_navigation_tree div.block a,
#pma_navigation_tree div.block u {
    position: absolute;
    left: 50%;
    top: 50%;
    z-index: 10;
}
#pma_navigation_tree div.block img {
    position: relative;
    top: -0.6em;
    left: 0;
    margin-left: -7px;
}
#pma_navigation_tree div.throbber img {
    top: 2px;
    left: 2px;
}
#pma_navigation_tree li.last > ul {
    background: none;
}
#pma_navigation_tree li > a, #pma_navigation_tree li > i {
    line-height: 1.5em;
    height: 1.5em;
    padding-left: 0.3em;
}
#pma_navigation_tree .list_container {
    border-left: 1px solid #666;
    margin-left: 0.75em;
    padding-left: 0.75em;
}
#pma_navigation_tree .last > .list_container {
    border-left: 0 solid #666;
}

/* Fast filter */
li.fast_filter {
    padding-left: 0.75em;
    margin-left: 0.75em;
    padding-right: 35px;
    border-left: 1px solid #666;
}
li.fast_filter input {
    padding-right: .4em;
    width: 100%;
}
li.fast_filter span {
    position: relative;
    right: 1.5em;
    padding: 0.2em;
    cursor: pointer;
    font-weight: bold;
    color: #800;
}
li.fast_filter.db_fast_filter {
    border: 0;
}

/* Resize handler */
#pma_navigation_resizer {
    width: 3px;
    height: 100%;
    background-color: #aaa;
    cursor: col-resize;
    position: fixed;
    top: 0;
    left: 240px;
    z-index: 801;
}
#pma_navigation_collapser {
    width: 20px;
    height: 22px;
    line-height: 22px;
    background: #eee;
    color: #555;
    font-weight: bold;
    position: fixed;
    top: 0;
    left: 240px;
    text-align: center;
    cursor: pointer;
    z-index: 800;
    text-shadow: 0px 1px 0px #fff;
    filter: dropshadow(color=#fff, offx=0, offy=1);
    border: 1px solid #888;
}

/* FILE: pmd.css.php */

/* Designer */
.input_tab {
    background-color: #A6C7E1;
    color: #000;
}

.content_fullscreen {
    position: relative;
    overflow: auto;
}

#canvas_outer {
    position: relative;
}

#canvas {
    background-color: #fff;
    color: #000;
}

canvas.pmd {
    display: inline-block;
    overflow: hidden;
    text-align: left;
}

canvas.pmd * {
    behavior: url(#default#VML);
}

.pmd_tab {
    background-color: #fff;
    color: #000;
    border-collapse: collapse;
    border: 1px solid #aaa;
    z-index: 1;
    -moz-user-select: none;
}

.tab_zag {
    background-image: url(./themes/pmahomme/img/pmd/Header.png);
    background-repeat: repeat-x;
    text-align: center;
    cursor: move;
    padding: 1px;
    font-weight: bold;
}

.tab_zag_2 {
    background-image: url(./themes/pmahomme/img/pmd/Header_Linked.png);
    background-repeat: repeat-x;
    text-align: center;
    cursor: move;
    padding: 1px;
    font-weight: bold;
}

.tab_field {
    background: #fff;
    color: #000;
    cursor: default;
}

.tab_field_2 {
    background-color: #CCFFCC;
    color: #000;
    background-repeat: repeat-x;
    cursor: default;
}

.tab_field_3 {
    background-color: #FFE6E6; /*#DDEEFF*/
    color: #000;
    cursor: default;
}

#pmd_hint {
    white-space: nowrap;
    position: absolute;
    background-color: #99FF99;
    color: #000;
    left: 200px;
    top: 50px;
    z-index: 3;
    border: #00CC66 solid 1px;
    display: none;
}

.scroll_tab {
    overflow: auto;
    width: 100%;
    height: 500px;
}

.pmd_Tabs {
    cursor: default;
    color: #0055bb;
    white-space: nowrap;
    text-decoration: none;
    text-indent: 3px;
    font-weight: bold;
    margin-left: 2px;
    text-align: left;
    background-color: #fff;
    background-image: url(./themes/pmahomme/img/pmd/left_panel_butt.png);
    border: #ccc solid 1px;
}

.pmd_Tabs2 {
    cursor: default;
    color: #0055bb;
    background: #FFEE99;
    text-indent: 3px;
    font-weight: bold;
    white-space: nowrap;
    text-decoration: none;
    border: #9999FF solid 1px;
    text-align: left;
}

.owner {
    font-weight: normal;
    color: #888;
}

.option_tab {
    padding-left: 2px;
    padding-right: 2px;
    width: 5px;
}

.select_all {
    vertical-align: top;
    padding-left: 2px;
    padding-right: 2px;
    cursor: default;
    width: 1px;
    color: #000;
    background-image: url(./themes/pmahomme/img/pmd/Header.png);
    background-repeat: repeat-x;
}

.small_tab {
    vertical-align: top;
    background-color: #0064ea;
    color: #fff;
    background-image: url(./themes/pmahomme/img/pmd/small_tab.png);
    cursor: default;
    text-align: center;
    font-weight: bold;
    padding-left: 2px;
    padding-right: 2px;
    width: 1px;
    text-decoration: none;
}

.small_tab2 {
    vertical-align: top;
    color: #fff;
    background-color: #FF9966;
    cursor: default;
    padding-left: 2px;
    padding-right: 2px;
    text-align: center;
    font-weight: bold;
    width: 1px;
    text-decoration: none;
}

.small_tab_pref {
    background-image: url(./themes/pmahomme/img/pmd/Header.png);
    background-repeat: repeat-x;
    text-align: center;
    width: 1px;
}

.small_tab_pref2 {
    vertical-align: top;
    color: #fff;
    background-color: #FF9966;
    cursor: default;
    text-align: center;
    font-weight: bold;
    width: 1px;
    text-decoration: none;
}

.butt {
    border: #4477aa solid 1px;
    font-weight: bold;
    height: 19px;
    width: 70px;
    background-color: #fff;
    color: #000;
    vertical-align: baseline;
}

.L_butt2_1 {
    padding: 1px;
    text-decoration: none;
    vertical-align: middle;
    cursor: default;
}

.L_butt2_2 {
    padding: 0;
    border: #0099CC solid 1px;
    background: #FFEE99;
    color: #000;
    text-decoration: none;
    vertical-align: middle;
    cursor: default;
}

/* ---------------------------------------------------------------------------*/
.bor {
    width: 10px;
    height: 10px;
}

.frams1 {
    background: url(./themes/pmahomme/img/pmd/1.png) no-repeat right bottom;
}

.frams2 {
    background: url(./themes/pmahomme/img/pmd/2.png) no-repeat left bottom;
}

.frams3 {
    background: url(./themes/pmahomme/img/pmd/3.png) no-repeat left top;
}

.frams4 {
    background: url(./themes/pmahomme/img/pmd/4.png) no-repeat right top;
}

.frams5 {
    background: url(./themes/pmahomme/img/pmd/5.png) repeat-x center bottom;
}

.frams6 {
    background: url(./themes/pmahomme/img/pmd/6.png) repeat-y left;
}

.frams7 {
    background: url(./themes/pmahomme/img/pmd/7.png) repeat-x top;
}

.frams8 {
    background: url(./themes/pmahomme/img/pmd/8.png) repeat-y right;
}

#osn_tab {
    background-color: #fff;
    color: #000;
    border: #A9A9A9 solid 1px;
}

.pmd_header {
    background-color: #EAEEF0;
    color: #000;
    text-align: center;
    font-weight: bold;
    margin: 0;
    padding: 0;
    background-image: url(./themes/pmahomme/img/pmd/top_panel.png);
    background-position: top;
    background-repeat: repeat-x;
    border-right: #999 solid 1px;
    border-left: #999 solid 1px;
    height: 28px;
    z-index: 101;
    width: 100%
}

.pmd_header a {
    display: block;
    float: left;
    margin: 3px 1px 4px;
    height: 20px;
    border: 1px dotted #fff;
}

.pmd_header .M_bord {
    display: block;
    float: left;
    margin: 4px;
    height: 20px;
    width: 2px;
}

.pmd_header a.first {
    margin-right: 1em;
}

.pmd_header a.last {
    margin-left: 1em;
}

a.M_butt_Selected_down_IE,
a.M_butt_Selected_down {
    border: 1px solid #C0C0BB;
    background-color: #99FF99;
    color: #000;
}

a.M_butt_Selected_down_IE:hover,
a.M_butt_Selected_down:hover,
a.M_butt:hover {
    border: 1px solid #0099CC;
    background-color: #FFEE99;
    color: #000;
}

#layer_menu {
    z-index: 100;
    position: absolute;
    left: 0;
    background-color: #EAEEF0;
    border: #999 solid 1px;
}

#layer_upd_relation {
    position: absolute;
    left: 637px;
    top: 224px;
    z-index: 100;
}

#layer_new_relation {
    position: absolute;
    left: 636px;
    top: 85px;
    z-index: 100;
    width: 153px;
}

#pmd_optionse {
    position: absolute;
    left: 636px;
    top: 85px;
    z-index: 100;
    width: 153px;
}

#layer_menu_sizer {
    background-image: url(./themes/pmahomme/img/pmd/resize.png);
    cursor: nw-resize;
    width: 16px;
    height: 16px;
}

.panel {
    position: fixed;
    top: 60px;
    right: 0;
    display: none;
    background: #FFF;
    border: 1px solid gray;
    width: 350 px;
    height: auto;
    padding: 30px 170px 30px;
    padding-left: 30px;
    color: #FFF;
    z-index: 102;
}

a.trigger {
    position: fixed;
    text-decoration: none;
    top: 60px;
    right: 0;
    color: #fff;
    padding: 10px 40px 10px 15px;
    background: #333 url(./themes/pmahomme/img/pmd/plus.png) 85% 55% no-repeat;
    border: 1px solid #444;
    display: block;
    z-index: 102;
}

a.trigger:hover {
    color: #080808;
    background: #fff696 url(./themes/pmahomme/img/pmd/plus.png) 85% 55% no-repeat;
    border: 1px solid #999;
}

a.active.trigger {
    background: #222 url(./themes/pmahomme/img/pmd/minus.png) 85% 55% no-repeat;
    z-index: 999;
}

a.active.trigger:hover {
    background: #fff696 url(./themes/pmahomme/img/pmd/minus.png) 85% 55% no-repeat;
}

h2.tiger {
    background-repeat: repeat-x;
    padding: 1px;
    font-weight: bold;
    padding: 50px 20px 50px;
    margin: 0 0 5px 0;
    width: 250px;
    float: left;
    color : #333;
    text-align: center;
}

h2.tiger a {
    background-image: url(./themes/pmahomme/img/pmd/Header.png);
    text-align: center;
    text-decoration: none;
    color : #333;
    display: block;
}

h2.tiger a:hover {
    color: #000;
    background-image: url(./themes/pmahomme/img/pmd/Header_Linked.png);
}

h2.active {
    background-image: url(./themes/pmahomme/img/pmd/Header.png);
    background-repeat: repeat-x;
    padding: 1px;
    background-position: left bottom;
}

.toggle_container {
    margin: 0 0 5px;
    padding: 0;
    border-top: 1px solid #d6d6d6;
    background: #FFF;
    width: 250px;
    overflow: hidden;
    font-size: 1.2em;
    clear: both;
}

.toggle_container .block {
    background-color: #DBE4E8;
    padding: 40px 15px 40px 15px; /*--Padding of Container--*/
    border:1px solid #999;
    color: #000;
}

.history_table {
    text-align: center;
    background-color: #9999CC;
}

.history_table2 {
    text-align: center;
    background-color: #DBE4E8;
}

#filter {
    display: none;
    position: absolute;
    top: 0%;
    left: 0%;
    width: 100%;
    height: 100%;
    background-color: #CCA;
    z-index: 10;
    opacity: .5;
    filter: alpha(opacity=50);
}

#box {
    display: none;
    position: absolute;
    top: 20%;
    left: 30%;
    width: 500px;
    height: 220px;
    padding: 48px;
    margin: 0;
    border: 1px solid #000;
    background-color: #fff;
    z-index: 101;
    overflow: visible;
}

#boxtitle {
    position: absolute;
    float: center;
    top: 0;
    left: 0;
    width: 593px;
    height: 20px;
    padding: 0;
    padding-top: 4px;
    margin: 0;
    border-bottom: 4px solid #3CF;
    background-color: #D0DCE0;
    color: black;
    font-weight: bold;
    padding-left: 2px;
    text-align: left;
}

#tblfooter {
    background-color: #D3DCE3;
    float: right;
    padding-top: 10px;
    color: black;
    font-weight: normal;
}

#foreignkeychk {
    text-align: left;
    position: absolute;
    cursor: pointer;
}

/* FILE: rte.css.php */

.rte_table {
    table-layout: fixed;
}

.rte_table td {
    vertical-align: middle;
    padding: 0.2em;
}

.rte_table tr td:nth-child(1) {
    font-weight: bold;
}

.rte_table input,
.rte_table select,
.rte_table textarea {
    width: 100%;
    margin: 0;
    box-sizing: border-box;
    -ms-box-sizing: border-box;
    -moz-box-sizing: border-box;
    -webkit-box-sizing: border-box;
}

.rte_table .routine_params_table {
    width: 100%;
}

/* FILE: codemirror.css.php */
.CodeMirror {
  line-height: 1em;
  font-family: monospace;
  background: #fff;
  border: 1px solid #000;
  /* Necessary so the scrollbar can be absolutely positioned within the wrapper on Lion. */
  position: relative;
  /* This prevents unwanted scrollbars from showing up on the body and wrapper in IE. */
  overflow: hidden;
}

.CodeMirror-scroll {
  overflow: auto;
  height: 18em;
  /* This is needed to prevent an IE[67] bug where the scrolled content
     is visible outside of the scrolling box. */
  position: relative;
  outline: none;
}

/* Vertical scrollbar */
.CodeMirror-scrollbar {
  position: absolute;
  right: 0; top: 0;
  overflow-x: hidden;
  overflow-y: scroll;
  z-index: 5;
}
.CodeMirror-scrollbar-inner {
  /* This needs to have a nonzero width in order for the scrollbar to appear
     in Firefox and IE9. */
  width: 1px;
}
.CodeMirror-scrollbar.cm-sb-overlap {
  /* Ensure that the scrollbar appears in Lion, and that it overlaps the content
     rather than sitting to the right of it. */
  position: absolute;
  z-index: 1;
  float: none;
  right: 0;
  min-width: 12px;
}
.CodeMirror-scrollbar.cm-sb-nonoverlap {
  min-width: 12px;
}
.CodeMirror-scrollbar.cm-sb-ie7 {
  min-width: 18px;
}

.CodeMirror-gutter {
  position: absolute; left: 0; top: 0;
  z-index: 10;
  background-color: #f7f7f7;
  border-right: 1px solid #eee;
  min-width: 2em;
  height: 100%;
}
.CodeMirror-gutter-text {
  color: #aaa;
  text-align: right;
  padding: .4em .2em .4em .4em;
  white-space: pre !important;
  cursor: default;
}
.CodeMirror-lines {
  padding: .4em;
  white-space: pre;
  cursor: text;
}

.CodeMirror pre {
  -moz-border-radius: 0;
  -webkit-border-radius: 0;
  -o-border-radius: 0;
  border-radius: 0;
  border-width: 0; margin: 0; padding: 0; background: transparent;
  font-family: inherit;
  font-size: inherit;
  padding: 0; margin: 0;
  white-space: pre;
  word-wrap: normal;
  line-height: inherit;
  color: inherit;
  overflow: visible;
}

.CodeMirror-wrap pre {
  word-wrap: break-word;
  white-space: pre-wrap;
  word-break: normal;
}
.CodeMirror-wrap .CodeMirror-scroll {
  overflow-x: hidden;
}

.CodeMirror textarea {
  outline: none !important;
  font-family: inherit !important;
  font-size: inherit !important;
}

.CodeMirror pre.CodeMirror-cursor {
  z-index: 10;
  position: absolute;
  visibility: hidden;
  border-left: 1px solid black !important;
  border-right: none;
  width: 0;
}
.cm-keymap-fat-cursor pre.CodeMirror-cursor {
  width: auto;
  border: 0;
  background: transparent;
  background: rgba(0, 200, 0, .4);
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr=#6600c800, endColorstr=#4c00c800);
}
/* Kludge to turn off filter in ie9+, which also accepts rgba */
.cm-keymap-fat-cursor pre.CodeMirror-cursor:not(#nonsense_id) {
  filter: progid:DXImageTransform.Microsoft.gradient(enabled=false);
}
.CodeMirror pre.CodeMirror-cursor.CodeMirror-overwrite {}
.CodeMirror-focused pre.CodeMirror-cursor {
  visibility: visible;
}

div.CodeMirror-selected { background: #d9d9d9; }
.CodeMirror-focused div.CodeMirror-selected { background: #d7d4f0; }

.CodeMirror-searching {
  background: #ffa;
  background: rgba(255, 255, 0, .4);
}


div.CodeMirror span.CodeMirror-matchingbracket {color: #0f0;}
div.CodeMirror span.CodeMirror-nonmatchingbracket {color: #f22;}

@media print {

  /* Hide the cursor when printing */
  .CodeMirror pre.CodeMirror-cursor {
    visibility: hidden;
  }

}

span.cm-keyword, span.cm-statement-verb {
    color: #909;
}
span.cm-variable {
    color: black;
}
span.cm-comment {
    color: #808000;
}
span.cm-mysql-string {
    color: #008000;
}
span.cm-operator {
    color: fuchsia;
}
span.cm-mysql-word {
    color: black;
}
span.cm-builtin {
    color: #f00;
}
span.cm-variable-2 {
    color: #f90;
}
span.cm-variable-3 {
    color: #00f;
}
span.cm-separator {
    color: fuchsia;
}
span.cm-number {
    color: teal;
}
/* FILE: jqplot.css.php */

/* jqPlot */

/*rules for the plot target div.  These will be cascaded down to all plot elements according to css rules*/
.jqplot-target {
    position: relative;
    color: #222222;
    font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
    font-size: 1em;
/*    height: 300px;
    width: 590px;*/
}

/*rules applied to all axes*/
.jqplot-axis {
    font-size: 0.75em;
}

.jqplot-xaxis {
    margin-top: 10px;
}

.jqplot-x2axis {
    margin-bottom: 10px;
}

.jqplot-yaxis {
    margin-right: 10px;
}

.jqplot-y2axis, .jqplot-y3axis, .jqplot-y4axis, .jqplot-y5axis, .jqplot-y6axis, .jqplot-y7axis, .jqplot-y8axis, .jqplot-y9axis, .jqplot-yMidAxis {
    margin-left: 10px;
    margin-right: 10px;
}

/*rules applied to all axis tick divs*/
.jqplot-axis-tick, .jqplot-xaxis-tick, .jqplot-yaxis-tick, .jqplot-x2axis-tick, .jqplot-y2axis-tick, .jqplot-y3axis-tick, .jqplot-y4axis-tick, .jqplot-y5axis-tick, .jqplot-y6axis-tick, .jqplot-y7axis-tick, .jqplot-y8axis-tick, .jqplot-y9axis-tick, .jqplot-yMidAxis-tick {
    position: absolute;
    white-space: pre;
}


.jqplot-xaxis-tick {
    top: 0px;
    /* initial position untill tick is drawn in proper place */
    left: 15px;
/*    padding-top: 10px;*/
    vertical-align: top;
}

.jqplot-x2axis-tick {
    bottom: 0px;
    /* initial position untill tick is drawn in proper place */
    left: 15px;
/*    padding-bottom: 10px;*/
    vertical-align: bottom;
}

.jqplot-yaxis-tick {
    right: 0px;
    /* initial position untill tick is drawn in proper place */
    top: 15px;
/*    padding-right: 10px;*/
    text-align: right;
}

.jqplot-yaxis-tick.jqplot-breakTick {
	right: -20px;
	margin-right: 0px;
	padding:1px 5px 1px;
/*	background-color: white;*/
	z-index: 2;
	font-size: 1.5em;
}

.jqplot-y2axis-tick, .jqplot-y3axis-tick, .jqplot-y4axis-tick, .jqplot-y5axis-tick, .jqplot-y6axis-tick, .jqplot-y7axis-tick, .jqplot-y8axis-tick, .jqplot-y9axis-tick {
    left: 0px;
    /* initial position untill tick is drawn in proper place */
    top: 15px;
/*    padding-left: 10px;*/
/*    padding-right: 15px;*/
    text-align: left;
}

.jqplot-yMidAxis-tick {
    text-align: center;
    white-space: nowrap;
}

.jqplot-xaxis-label {
    margin-top: 10px;
    font-size: 11pt;
    position: absolute;
}

.jqplot-x2axis-label {
    margin-bottom: 10px;
    font-size: 11pt;
    position: absolute;
}

.jqplot-yaxis-label {
    margin-right: 10px;
/*    text-align: center;*/
    font-size: 11pt;
    position: absolute;
}

.jqplot-yMidAxis-label {
    font-size: 11pt;
    position: absolute;
}

.jqplot-y2axis-label, .jqplot-y3axis-label, .jqplot-y4axis-label, .jqplot-y5axis-label, .jqplot-y6axis-label, .jqplot-y7axis-label, .jqplot-y8axis-label, .jqplot-y9axis-label {
/*    text-align: center;*/
    font-size: 11pt;
    margin-left: 10px;
    position: absolute;
}

.jqplot-meterGauge-tick {
    font-size: 0.75em;
    color: #999999;
}

.jqplot-meterGauge-label {
    font-size: 1em;
    color: #999999;
}

table.jqplot-table-legend {
    margin-top: 12px;
    margin-bottom: 12px;
    margin-left: 12px;
    margin-right: 12px;
}

table.jqplot-table-legend, table.jqplot-cursor-legend {
    background-color: rgba(255,255,255,0.6);
    border: 1px solid #cccccc;
    position: absolute;
    font-size: 0.75em;
}

td.jqplot-table-legend {
    vertical-align: middle;
}

/*
These rules could be used instead of assigning
element styles and relying on js object properties.
*/

/*
td.jqplot-table-legend-swatch {
    padding-top: 0.5em;
    text-align: center;
}

tr.jqplot-table-legend:first td.jqplot-table-legend-swatch {
    padding-top: 0px;
}
*/

td.jqplot-seriesToggle:hover, td.jqplot-seriesToggle:active {
    cursor: pointer;
}

.jqplot-table-legend .jqplot-series-hidden {
    text-decoration: line-through;
}

div.jqplot-table-legend-swatch-outline {
    border: 1px solid #cccccc;
    padding: 1px;
}

div.jqplot-table-legend-swatch {
    width: 0;
    height: 0;
    border-top-width: 5px;
    border-bottom-width: 5px;
    border-left-width: 6px;
    border-right-width: 6px;
    border-top-style: solid;
    border-bottom-style: solid;
    border-left-style: solid;
    border-right-style: solid;
}

.jqplot-title {
    top: 0px;
    left: 0px;
    padding-bottom: 0.5em;
    font-size: 1.2em;
}

table.jqplot-cursor-tooltip {
    border: 1px solid #cccccc;
    font-size: 0.75em;
}


.jqplot-cursor-tooltip {
    border: 1px solid #cccccc;
    font-size: 0.75em;
    white-space: nowrap;
    background: rgba(208,208,208,0.5);
    padding: 1px;
}

.jqplot-highlighter-tooltip, .jqplot-canvasOverlay-tooltip {
    border: 1px solid #cccccc;
    font-size: 0.75em;
    white-space: nowrap;
    background: rgba(208,208,208,0.5);
    padding: 1px;
}

.jqplot-point-label {
    font-size: 0.75em;
    z-index: 2;
}
      
td.jqplot-cursor-legend-swatch {
    vertical-align: middle;
    text-align: center;
}

div.jqplot-cursor-legend-swatch {
    width: 1.2em;
    height: 0.7em;
}

.jqplot-error {
/*   Styles added to the plot target container when there is an error go here.*/
    text-align: center;
}

.jqplot-error-message {
/*    Styling of the custom error message div goes here.*/
    position: relative;
    top: 46%;
    display: inline-block;
}

div.jqplot-bubble-label {
    font-size: 0.8em;
/*    background: rgba(90%, 90%, 90%, 0.15);*/
    padding-left: 2px;
    padding-right: 2px;
    color: rgb(20%, 20%, 20%);
}

div.jqplot-bubble-label.jqplot-bubble-label-highlight {
    background: rgba(90%, 90%, 90%, 0.7);
}

div.jqplot-noData-container {
	text-align: center;
	background-color: rgba(96%, 96%, 96%, 0.3);
}

/* FILE: resizable-menu.css.php */
ul.resizable-menu a,
ul.resizable-menu span {
    display: block;
    margin: 0;
    padding: 0;
    white-space: nowrap;
}

ul.resizable-menu .submenu {
    display: none;
    position: relative;
}

ul.resizable-menu .shown {
    display: inline-block;
}

ul.resizable-menu ul {
    margin: 0;
    padding: 0;
    position: absolute;
    list-style-type: none;
    display: none;
    border: 1px #ddd solid;
    z-index: 2;
    right: 0;
}

ul.resizable-menu li:hover {
    background-image: url(./themes/svg_gradient.php?from=ffffff&to=e5e5e5);
background-size: 100% 100%;
background: -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#e5e5e5));
background: -webkit-linear-gradient(top, #ffffff, #e5e5e5);
background: -moz-linear-gradient(top, #ffffff, #e5e5e5);
background: -ms-linear-gradient(top, #ffffff, #e5e5e5);
background: -o-linear-gradient(top, #ffffff, #e5e5e5);}

ul.resizable-menu li:hover ul,
ul.resizable-menu .submenuhover ul {
    display: block;
    background: #fff;
}

ul.resizable-menu ul li {
    width: 100%;
}
/* Icon sprites */
.icon {
    margin: 0 .3em;
    padding: 0 !important;
    width: 16px;
    height: 16px;
    background-image: url('./themes/pmahomme/img/sprites.png') !important;
    background-repeat: no-repeat !important;
    background-position: top left !important;
}
.ic_asc_order { background-position: 0 -16px !important; }
.ic_b_bookmark { background-position: 0 -32px !important; }
.ic_b_browse { background-position: 0 -48px !important; }
.ic_b_calendar { background-position: 0 -64px !important; }
.ic_b_chart { background-position: 0 -80px !important; }
.ic_b_close { background-position: 0 -96px !important; }
.ic_b_column_add { background-position: 0 -112px !important; }
.ic_b_comment { background-position: 0 -128px !important; }
.ic_bd_browse { background-position: 0 -144px !important; }
.ic_b_dbstatistics { background-position: 0 -160px !important; }
.ic_bd_deltbl { background-position: 0 -176px !important; }
.ic_bd_drop { background-position: 0 -192px !important; }
.ic_bd_edit { background-position: 0 -208px !important; }
.ic_b_deltbl { background-position: 0 -224px !important; }
.ic_bd_empty { background-position: 0 -240px !important; }
.ic_bd_export { background-position: 0 -256px !important; }
.ic_bd_firstpage { background-position: 0 -272px !important; }
.ic_bd_ftext { background-position: 0 -288px !important; }
.ic_bd_index { background-position: 0 -304px !important; }
.ic_bd_insrow { background-position: 0 -320px !important; }
.ic_bd_lastpage { background-position: 0 -336px !important; }
.ic_bd_nextpage { background-position: 0 -352px !important; }
.ic_b_docs { background-position: 0 -368px !important; }
.ic_b_docsql { background-position: 0 -384px !important; }
.ic_bd_prevpage { background-position: 0 -400px !important; }
.ic_bd_primary { background-position: 0 -416px !important; }
.ic_b_drop { background-position: 0 -432px !important; }
.ic_bd_sbrowse { background-position: 0 -448px !important; }
.ic_bd_select { background-position: 0 -464px !important; }
.ic_bd_spatial { background-position: 0 -480px !important; }
.ic_bd_unique { background-position: 0 -496px !important; }
.ic_b_edit { background-position: 0 -512px !important; }
.ic_b_empty { background-position: 0 -528px !important; }
.ic_b_engine { background-position: 0 -544px !important; }
.ic_b_event_add { background-position: 0 -560px !important; }
.ic_b_events { background-position: 0 -576px !important; }
.ic_b_export { background-position: 0 -592px !important; }
.ic_b_firstpage { background-position: 0 -608px !important; }
.ic_b_ftext { background-position: 0 -624px !important; }
.ic_b_group { background-position: 0 -640px !important; }
.ic_b_help { background-position: 0 -656px !important; }
.ic_b_home { background-position: 0 -672px !important; }
.ic_b_import { background-position: 0 -688px !important; }
.ic_b_index_add { background-position: 0 -704px !important; }
.ic_b_index { background-position: 0 -720px !important; }
.ic_b_info { background-position: 0 -736px !important; width: 11px; height: 11px; }
.ic_b_inline_edit { background-position: 0 -752px !important; }
.ic_b_insrow { background-position: 0 -768px !important; }
.ic_b_lastpage { background-position: 0 -784px !important; }
.ic_b_minus { background-position: 0 -800px !important; }
.ic_b_more { background-position: 0 -816px !important; }
.ic_b_move { background-position: 0 -832px !important; }
.ic_b_newdb { background-position: 0 -848px !important; }
.ic_b_newtbl { background-position: 0 -864px !important; }
.ic_b_nextpage { background-position: 0 -880px !important; }
.ic_b_pdfdoc { background-position: 0 -896px !important; }
.ic_b_plus { background-position: 0 -912px !important; }
.ic_b_prevpage { background-position: 0 -928px !important; }
.ic_b_primary { background-position: 0 -944px !important; }
.ic_b_print { background-position: 0 -960px !important; }
.ic_b_props { background-position: 0 -976px !important; }
.ic_b_relations { background-position: 0 -992px !important; }
.ic_b_routine_add { background-position: 0 -1008px !important; }
.ic_b_routines { background-position: 0 -1024px !important; }
.ic_b_save { background-position: 0 -1040px !important; }
.ic_b_sbrowse { background-position: 0 -1056px !important; }
.ic_b_sdb { background-position: 0 -1072px !important; width: 10px; height: 10px; }
.ic_b_search { background-position: 0 -1088px !important; }
.ic_b_selboard { background-position: 0 -1104px !important; }
.ic_b_select { background-position: 0 -1120px !important; }
.ic_b_snewtbl { background-position: 0 -1136px !important; }
.ic_b_spatial { background-position: 0 -1152px !important; }
.ic_b_sqldoc { background-position: 0 -1168px !important; }
.ic_b_sqlhelp { background-position: 0 -1184px !important; }
.ic_b_sql { background-position: 0 -1200px !important; }
.ic_b_table_add { background-position: 0 -1216px !important; }
.ic_b_tblanalyse { background-position: 0 -1232px !important; }
.ic_b_tblexport { background-position: 0 -1248px !important; }
.ic_b_tblimport { background-position: 0 -1264px !important; }
.ic_b_tblops { background-position: 0 -1280px !important; }
.ic_b_tbloptimize { background-position: 0 -1296px !important; }
.ic_b_tipp { background-position: 0 -1312px !important; }
.ic_b_trigger_add { background-position: 0 -1328px !important; }
.ic_b_triggers { background-position: 0 -1344px !important; }
.ic_b_unique { background-position: 0 -1360px !important; }
.ic_b_usradd { background-position: 0 -1376px !important; }
.ic_b_usrcheck { background-position: 0 -1392px !important; }
.ic_b_usrdrop { background-position: 0 -1408px !important; }
.ic_b_usredit { background-position: 0 -1424px !important; }
.ic_b_usrlist { background-position: 0 -1440px !important; }
.ic_b_view_add { background-position: 0 -1456px !important; }
.ic_b_view { background-position: 0 -1472px !important; }
.ic_b_views { background-position: 0 -1488px !important; }
.ic_col_drop { background-position: 0 -1504px !important; }
.ic_database { background-position: 0 -1520px !important; }
.ic_eye_grey { background-position: 0 -1536px !important; }
.ic_eye { background-position: 0 -1552px !important; }
.ic_item { background-position: 0 -1568px !important; width: 9px; height: 9px; }
.ic_more { background-position: 0 -1584px !important; width: 13px; }
.ic_new_data_hovered { background-position: 0 -1600px !important; }
.ic_new_data { background-position: 0 -1616px !important; }
.ic_new_data_selected_hovered { background-position: 0 -1632px !important; }
.ic_new_data_selected { background-position: 0 -1648px !important; }
.ic_new_struct_hovered { background-position: 0 -1664px !important; }
.ic_new_struct { background-position: 0 -1680px !important; }
.ic_new_struct_selected_hovered { background-position: 0 -1696px !important; }
.ic_new_struct_selected { background-position: 0 -1712px !important; }
.ic_pause { background-position: 0 -1728px !important; }
.ic_php_sym { background-position: 0 -1744px !important; }
.ic_play { background-position: 0 -1760px !important; }
.ic_s_asci { background-position: 0 -1776px !important; }
.ic_s_asc { background-position: 0 -1792px !important; }
.ic_s_attention { background-position: 0 -1808px !important; }
.ic_s_cancel2 { background-position: 0 -1824px !important; }
.ic_s_cancel { background-position: 0 -1840px !important; }
.ic_s_cog { background-position: 0 -1856px !important; }
.ic_s_db { background-position: 0 -1872px !important; }
.ic_s_desc { background-position: 0 -1888px !important; }
.ic_s_error2 { background-position: 0 -1904px !important; width: 11px; height: 11px; }
.ic_s_error { background-position: 0 -1920px !important; }
.ic_s_host { background-position: 0 -1936px !important; }
.ic_s_info { background-position: 0 -1952px !important; }
.ic_s_lang { background-position: 0 -1968px !important; }
.ic_s_loggoff { background-position: 0 -1984px !important; }
.ic_s_notice { background-position: 0 -2000px !important; }
.ic_s_okay { background-position: 0 -2016px !important; }
.ic_s_passwd { background-position: 0 -2032px !important; }
.ic_s_process { background-position: 0 -2048px !important; }
.ic_s_really { background-position: 0 -2064px !important; width: 11px; height: 11px; }
.ic_s_reload { background-position: 0 -2080px !important; }
.ic_s_replication { background-position: 0 -2096px !important; }
.ic_s_rights { background-position: 0 -2112px !important; }
.ic_s_sortable { background-position: 0 -2128px !important; }
.ic_s_status { background-position: 0 -2144px !important; }
.ic_s_success { background-position: 0 -2160px !important; }
.ic_s_sync { background-position: 0 -2176px !important; }
.ic_s_tbl { background-position: 0 -2192px !important; }
.ic_s_theme { background-position: 0 -2208px !important; }
.ic_s_top { background-position: 0 -2224px !important; }
.ic_s_vars { background-position: 0 -2240px !important; }
.ic_s_views { background-position: 0 -2256px !important; }
.ic_window-new { background-position: 0 -2272px !important; }
img.sortableIcon { background-position: 0 -2128px; height: 16px; width: 16px; }
th.headerSortUp img.sortableIcon { background-position: 0 -1792px; height: 16px; width: 16px; }
th.headerSortDown img.sortableIcon { background-position: 0 -1888px; height: 16px; width: 16px; }
