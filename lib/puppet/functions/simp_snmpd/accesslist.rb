# parse the access hash and return strings that for access entries for
#  the snmpd.conf file
#  @see The SIMP user guide HOW TO: Configure SNMPD describes the hashes in
#    detail.
Puppet::Functions.create_function(:'simp_snmpd::accesslist') do
  # @param access_hash
  #    The list of accesses to create.
  # @param defaultmodel
  #    The default Security model to use if that entry is not defined in the hash entry
  # @param defaultlevel
  #    The default Security level to use if that entry is not defined in the hash entry
  #
  # @return
  #   An array of strings that define VACM access lines for use in snmpd.conf files.
  dispatch :createlist do
    param 'Hash', :access_hash
    param 'String', :defaultmodel
    param 'String', :defaultlevel
  end

  def createlist(access_hash,defaultmodel,defaultlevel)
   # access GROUP CONTEXT {any|v1|v2c|usm|tsm|ksm} LEVEL PREFX READ WRITE NOTIFY']
    accesslist = []
    access_hash.each { | name, values|
      if ! values.nil? and ! values.empty?  then
        if  values.has_key?('view') and values.has_key?('groups')  then
          model = defaultmodel
          level = defaultlevel
          view = { 'read' => 'none', 'write' => 'none', 'notify' => 'none'}
          prefx = 'exact'
          context = '""'
          values.each { |key, setting|
            case key
            when 'model'
              if ['any','v1','v2c','usm','tsm','ksm'].include? setting then
                model = setting
              else
                fail("simp_snmpd: access_hash - model is:  #{setting} model must be one of 'any','v1','v2c','usm','tsm','ksm'")
              end
            when 'view'
              if setting.is_a?(Hash) then
                setting.each { |type, value|
                  case type
                  when /^(read|write|notify)$/
                    view[type] = value
                  else
                    fail("simp_snmpd: access_hash - invalid key #{type} in view must be read, write, or notify")
                  end
                }
                view = "#{view['read']} #{view['write']} #{view['notify']}"
              else
                fail("simp_snmpd: access_hash - expects a hash for view with one or more of read, write, notify keys.")
              end
            when 'level'
              if ['auth','priv','noauth'].include? setting then
                level = setting
              else
                fail("simp_snmpd: access_hash - level is:  #{setting} level must be one of 'auth','priv','noauth'")
              end
            when 'context'
               context = setting
            when /^(prefx|prefix)$/
              if ['exact','prefix'].include? setting then
                  prefx = setting
              else
                fail("simp_snmpd: access_hash - prefix is:  #{setting} level must be one of 'exact' or 'prefix'")
              end
            when 'groups'
              if values['groups'].is_a?(Array) then
                groups = values['groups']
              else
                groups = [ values['groups'] ]
              end
            else
              fail("simp_snmpd: access_hash #{name} has invalid key #{key}")
            end
          }
          if values['groups'].is_a?(Array) then
            groups = values['groups']
          else
            groups = [ values['groups'] ]
          end
          groups.each { |group|
            accesslist.push("#{group} #{context} #{model} #{level} #{prefx} #{view}")
          }
        else
          fail("simp_snmpd: access_hash definition #{name} is missing either view or groups key.")
        end
      end
    }
    accesslist
  end
end
