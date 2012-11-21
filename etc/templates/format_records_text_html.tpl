{#
## This file is part of Invenio.
## Copyright (C) 2012 CERN.
##
## Invenio is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation; either version 2 of the
## License, or (at your option) any later version.
##
## Invenio is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Invenio; if not, write to the Free Software Foundation, Inc.,
## 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
#}

{% from "websearch_helpers.html" import record_brief_links with context %}

{% macro render_search_pagination(pagination) %}
  {%- set args = request.args.copy().to_dict() -%}
  {%- set form_args = request.form.copy().to_dict() -%}
  {%- if form_args|length() and 'filter' in form_args -%}
    {%- do form_args.pop('filter') -%}
    {%- do args.update(form_args) -%}
    {%- set hash_tag = '#'+request.form.get('filter','') -%}
  {%- else -%}
    {%- set hash_tag = '' -%}
  {%- endif -%}
  <div style="margin:0px;" class="pagination pull-right">
    <ul>
      <li{{ ' class="disabled"'|safe if not pagination.has_prev }}>
        {%- do args.update({'jrec': 1}) -%}
        <a title="first" href="{{ url_for('search.search', **args)+hash_tag }}">«</a></li>
      <li{{ ' class="disabled"'|safe if not pagination.has_prev }}>
        {%- set jrec = (pagination.page-1)*pagination.per_page if pagination.has_prev else 1 -%}
        {%- do args.update({'jrec': jrec}) -%}
        <a title="prev" href="{{ url_for('search.search', **args)+hash_tag }}">&lsaquo;</a></li>
      {%- for page in pagination.iter_pages() %}
        {%- if page -%}
      <li{{ ' class="active"'|safe if page == pagination.page }}>
        {%- do args.update({'jrec': (page-1)*pagination.per_page+1}) -%}
        <a href="{{ url_for('search.search', **args)+hash_tag }}">{{ page }}</a>
      </li>
        {%- else -%}
          <li class="disabled"><a href="{{ hash_tag|default('#', true) }}">...</a></li>
        {%- endif -%}
      {%- endfor -%}
      <li{{ ' class="disabled"'|safe if not pagination.has_next }}>
        {%- set jrec = (pagination.page+1)*pagination.per_page if pagination.has_next else (pagination.pages-1)*pagination.per_page+1 -%}
        {%- do args.update({'jrec': jrec}) -%}

        <a href="{{ url_for('search.search', **args)+hash_tag }}">&rsaquo;</a></li>
      <li{{ ' class="disabled"'|safe if not pagination.has_next }}>
        {%- do args.update({'jrec': (pagination.pages-1)*pagination.per_page+1}) -%}
        <a title="last" href="{{ url_for('search.search', **args)+hash_tag }}">»</a>
      </li>
    </ul>
  </div>
{% endmacro %}


{% macro render_search_results(recids, collection, pagination, format_record) %}
      <form class="clearfix form-horizontal" name="" action="{{ url_for('search.dispatch') }}" method="post">
        <span class="btn-group">
          <span onclick="$('[name=recid]').prop('checked', function() {return !$(this).prop('checked')});"
                class="btn">
            <i class="icon icon-check"
               rel="tooltip"
               title="{{ _('Toggle all') }}"></i>
          </span>
          <button name="action" value="addtobasket" class="btn">
            <i class="icon icon-bookmark"
               rel="tooltip"
               title="{{ _('Add to basket') }}"></i>
          </button>
        </span>
        <p class="help-inline hidden-phone">
          {%- set r_from = (pagination.page-1)*pagination.per_page+1 -%}
          {%- set r_to = pagination.page*pagination.per_page -%}
          {%- set r_of = recids|length -%}
          {%- set r_to = r_to if r_to < r_of else r_of -%}
          {{ _('Showing recods %d to %d out of %d results.') % (r_from, r_to, r_of) }}
        </p>
        <div class="btn-group pull-right">

          <a class="btn dropdown-toggle" data-toggle="dropdown" href="#">
            <i class="icon-random"></i> {{ _('Sort by') }}
            <span class="caret"></span>
          </a>

          {%- set args = request.values.copy().to_dict() -%}
          {%- set form_args = request.form.copy().to_dict() -%}
          {%- if form_args|length() and 'filter' in form_args -%}
            {%- do form_args.pop('filter') -%}
            {%- do args.update(form_args) -%}
          {%- endif -%}
          {%- set new_args = args.copy() -%}
          {%- if 'so' in new_args -%}
            {%- do new_args.pop('so') -%}
          {%- endif -%}
          {%- if 'rm' in new_args -%}
            {%- do new_args.pop('rm') -%}
          {%- endif -%}

          <ul class="dropdown-menu">
          {%- for (k,v,vv) in [('Most recent', 'rm', ''), ('Most cited', 'rm', 'citation'), ('Most relevant', 'rm', 'wrd')] -%}
            {%- set active = request.values.get(v,'') == vv -%}
            {%- set used_args = new_args.copy() -%}
            {%- do used_args.update({v:vv}) -%}
            <li>
            <a href="{{ url_for('search.search', **used_args) }}{{ '#'+request.form.get('filter','')|default('', true) }}"
               class="{{ 'active' if active }}">
              <i class="pull-right icon {{ ' icon-ok' if active }}"></i>
                {{ _(k) }}
            </a>
            </li>
          {%- endfor -%}
            </li>
          </ul>
        </div>

        <div class="btn-group pull-right" style="margin-right: 5px;">
          <a class="btn dropdown-toggle" data-toggle="dropdown" href="#">
            <i class="icon-th"></i> {{ _('Display') }}
            <span class="caret"></span>
          </a>
          <ul class="dropdown-menu">
          {%- for i in collection.formatoptions if i.content_type == 'text/html' and i.visibility == 1 -%}
            {%- set used_args = new_args.copy() -%}
            {%- do used_args.update({'of':i.code}) -%}
            <li><a
               href="{{ url_for('search.search', **used_args) }}{{ '#'+request.form.get('filter','')|default('', true) }}"
               class="{{ ' active' if active }}">
              <i class="pull-right icon {{ ' icon-ok' if request.args.get('of','hb')==i.code }}"></i>
              {{ i.name }}
            </a></li>
          {%- endfor -%}
          <!-- dropdown menu links -->
          </ul>
        </div>


        <hr/>

        {%- set of = request.values.get('of', 'hb') -%}
        {%- for recid in recids[(pagination.page-1)*rg:pagination.page*rg] -%}
          {%- if of[0] == 'h' -%}
            <div class="row-fluid">
              <div class="span1">
                <label class="pull-right">
                  <input type="checkbox" name="recid" value="{{ recid }}" />
                  <abbr class="unapi-id" title="{{ recid }}"></abbr>
                  {{ loop.index+(pagination.page-1)*rg }}
                </label>
              </div>
              <div class="span11">
                {{ format_record(recid)|safe }}
                {{ record_brief_links(recid) }}
              </div>
            </div>
          {%- else -%}
          {{ format_record(recid) }}
          {%- endif -%}
        {%- endfor -%}
        <hr/>
        <div class="row clearfix">
          <div class="span10">
            <span class="pull-left btn-group clearfix">
            <span onclick="$('[name=recid]').prop('checked', function() {return !$(this).prop('checked')});"
                  class="btn">
              <i class="icon icon-check"
                 rel="tooltip"
                 title="{{ _('Toggle all') }}"></i>
            </span>
            <button name="action" value="addtobasket" class="btn">
              <i class="icon icon-bookmark"
                 rel="tooltip"
                 title="{{ _('Add to basket') }}"></i>
            </button>
           </span>
            <span class="span4">
              <select name="of" class="span2">
              {%- for i in export_formats -%}
                <option value="{{ i.code }}"{{ ' selected' if request.args.get('of','hb')==i.code }}>{{ i.name }}</option>
              {%- endfor -%}
              </select>
             <button name="action" value="export" class="btn">
              <i class="icon icon-download-alt"
                 rel="tooltip"
                 title="{{ _('Export') }}"></i> {{ _('Export') }}
             </button>
            </span>

            {{ render_search_pagination(pagination) }}
          </div>
        </div>
      </form>
{% endmacro %}

{{ render_search_results(recids, collection, pagination, format_record) }}
