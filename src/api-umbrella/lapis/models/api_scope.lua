local api_scope_policy = require "api-umbrella.lapis.policies.api_scope_policy"
local common_validations = require "api-umbrella.utils.common_validations"
local iso8601 = require "api-umbrella.utils.iso8601"
local json_null = require("cjson").null
local model_ext = require "api-umbrella.utils.model_ext"
local t = require("resty.gettext").gettext
local validation_ext = require "api-umbrella.utils.validation_ext"

local validate_field = model_ext.validate_field
local validate_uniqueness = model_ext.validate_uniqueness

local ApiScope
ApiScope = model_ext.new_class("api_scopes", {
  display_name = function(self)
    return self.name .. " - " .. self.host .. self.path_prefix
  end,

  authorize = function(self)
    api_scope_policy.authorize_show(ngx.ctx.current_admin, self:attributes())
  end,

  as_json = function(self)
    return {
      id = self.id or json_null,
      name = self.name or json_null,
      host = self.host or json_null,
      path_prefix = self.path_prefix or json_null,
      created_at = iso8601.format_postgres(self.created_at) or json_null,
      created_by = self.created_by_id or json_null,
      creator = {
        username = self.created_by_username or json_null,
      },
      updated_at = iso8601.format_postgres(self.updated_at) or json_null,
      updated_by = self.updated_by_id or json_null,
      updater = {
        username = self.updated_by_username or json_null,
      },
      deleted_at = json_null,
      version = 1,
    }
  end,

  is_root = function(self)
    return self.path_prefix == "/"
  end
}, {
  authorize = function(data)
    api_scope_policy.authorize_modify(ngx.ctx.current_admin, data)
  end,

  validate = function(_, data)
    local errors = {}
    validate_field(errors, data, "name", validation_ext.string:minlen(1), t("can't be blank"))
    validate_field(errors, data, "host", validation_ext.string:minlen(1), t("can't be blank"))
    validate_field(errors, data, "host", validation_ext:regex(common_validations.host_format_with_wildcard, "jo"), t('must be in the format of "example.com"'))
    validate_field(errors, data, "path_prefix", validation_ext.string:minlen(1), t("can't be blank"))
    validate_field(errors, data, "path_prefix", validation_ext:regex(common_validations.url_prefix_format, "jo"), t('must start with "/"'))
    validate_uniqueness(errors, data, "path_prefix", ApiScope, {
      "host",
      "path_prefix",
    })
    return errors
  end,
})

return ApiScope
