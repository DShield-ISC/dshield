/**
 * Returns an HTML IMG tag for a particular image from a theme,
 * which may be an actual file or an icon from a sprite
 *
 * @param string image      The name of the file to get
 * @param string alternate  Used to set 'alt' and 'title' attributes of the image
 * @param object attributes An associative array of other attributes
 *
 * @return Object The requested image, this object has two methods:
 *                  .toString()        - Returns the IMG tag for the requested image
 *                  .attr(name)        - Returns a particular attribute of the IMG
 *                                       tag given it's name
 *                  .attr(name, value) - Sets a particular attribute of the IMG
 *                                       tag to the given value
 *                And one property:
 *                  .isSprite          - Whether the image is a sprite or not
 */
function PMA_getImage(image, alternate, attributes) {
    var in_array = function (needle, haystack) {
        for (var i in haystack) {
            if (haystack[i] == needle) {
                return true;
            }
        }
        return false;
    };
    var sprites = [
        'asc_order',
        'b_bookmark',
        'b_browse',
        'b_calendar',
        'b_chart',
        'b_close',
        'b_column_add',
        'b_comment',
        'bd_browse',
        'b_dbstatistics',
        'bd_deltbl',
        'bd_drop',
        'bd_edit',
        'b_deltbl',
        'bd_empty',
        'bd_export',
        'bd_firstpage',
        'bd_ftext',
        'bd_index',
        'bd_insrow',
        'bd_lastpage',
        'bd_nextpage',
        'b_docs',
        'b_docsql',
        'bd_prevpage',
        'bd_primary',
        'b_drop',
        'bd_sbrowse',
        'bd_select',
        'bd_spatial',
        'bd_unique',
        'b_edit',
        'b_empty',
        'b_engine',
        'b_event_add',
        'b_events',
        'b_export',
        'b_firstpage',
        'b_ftext',
        'b_group',
        'b_help',
        'b_home',
        'b_import',
        'b_index_add',
        'b_index',
        'b_info',
        'b_inline_edit',
        'b_insrow',
        'b_lastpage',
        'b_minus',
        'b_more',
        'b_move',
        'b_newdb',
        'b_newtbl',
        'b_nextpage',
        'b_pdfdoc',
        'b_plus',
        'b_prevpage',
        'b_primary',
        'b_print',
        'b_props',
        'b_relations',
        'b_routine_add',
        'b_routines',
        'b_save',
        'b_sbrowse',
        'b_sdb',
        'b_search',
        'b_selboard',
        'b_select',
        'b_snewtbl',
        'b_spatial',
        'b_sqldoc',
        'b_sqlhelp',
        'b_sql',
        'b_table_add',
        'b_tblanalyse',
        'b_tblexport',
        'b_tblimport',
        'b_tblops',
        'b_tbloptimize',
        'b_tipp',
        'b_trigger_add',
        'b_triggers',
        'b_unique',
        'b_usradd',
        'b_usrcheck',
        'b_usrdrop',
        'b_usredit',
        'b_usrlist',
        'b_view_add',
        'b_view',
        'b_views',
        'col_drop',
        'database',
        'eye_grey',
        'eye',
        'item',
        'more',
        'new_data_hovered',
        'new_data',
        'new_data_selected_hovered',
        'new_data_selected',
        'new_struct_hovered',
        'new_struct',
        'new_struct_selected_hovered',
        'new_struct_selected',
        'pause',
        'php_sym',
        'play',
        's_asci',
        's_asc',
        's_attention',
        's_cancel2',
        's_cancel',
        's_cog',
        's_db',
        's_desc',
        's_error2',
        's_error',
        's_host',
        's_info',
        's_lang',
        's_loggoff',
        's_notice',
        's_okay',
        's_passwd',
        's_process',
        's_really',
        's_reload',
        's_replication',
        's_rights',
        's_sortable',
        's_status',
        's_success',
        's_sync',
        's_tbl',
        's_theme',
        's_top',
        's_vars',
        's_views',
        'window-new'
    ];
    // custom image object, it will eventually be returned by this functions
    var retval = {
        data: {
            // this is private
            alt: '',
            title: '',
            src: (typeof PMA_TEST_THEME == 'undefined' ? '' : '../')
                + 'themes/dot.gif'
        },
        isSprite: true,
        attr: function (name, value) {
            if (value == undefined) {
                if (this.data[name] == undefined) {
                    return '';
                } else {
                    return this.data[name];
                }
            } else {
                this.data[name] = value;
            }
        },
        toString: function () {
            var retval = '<' + 'img';
            for (var i in this.data) {
                retval += ' ' + i + '="' + this.data[i] + '"';
            }
            retval += ' /' + '>';
            return retval;
        }
    };
    // initialise missing parameters
    if (attributes == undefined) {
        attributes = {};
    }
    if (alternate == undefined) {
        alternate = '';
    }
    // set alt
    if (attributes.alt != undefined) {
        retval.attr('alt', attributes.alt);
    } else {
        retval.attr('alt', alternate);
    }
    // set title
    if (attributes.title != undefined) {
        retval.attr('title', attributes.title);
    } else {
        retval.attr('title', alternate);
    }
    // set src
    var klass = image.replace('.gif', '').replace('.png', '');
    if (in_array(klass, sprites)) {
        // it's an icon from a sprite
        retval.attr('class', 'icon ic_' + klass);
    } else {
        // it's an image file
        retval.isSprite = false;
        retval.attr('src', "./themes/pmahomme/img/" + image);
    }
    // set all other attrubutes
    for (var i in attributes) {
        if (i == 'src') {
            // do not allow to override the 'src' attribute
            continue;
        } else if (i == 'class') {
            retval.attr(i, retval.attr('class') + ' ' + attributes[i]);
        } else {
            retval.attr(i, attributes[i]);
        }
    }

    return retval;
}
//