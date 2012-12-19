require 'net/ldap'

# Restrict ability to manipulate LDAP database outside of modifying an existing record
class Net::LDAP
  %w(rename delete add).each do |method|
    define_method(method) do |*args|
      puts "Unauthorized LDAP modification attempted"
      return false
    end
  end
end

class WrapLdap
  attr_accessor :ldap

  def initialize(env=:staging)
    @ldap = Net::LDAP.new
    
    if env == :production
      @ldap.host = "YOUR PROD HOST HERE"
      @ldap.port = 389
      @ldap.auth "YOUR STRING HERE", "YOUR PROD PASS HERE"
    else  
      @ldap.host = "YOUR STAGE HOST HERE"
      @ldap.port = 389
      @ldap.auth "YOUR STRING HERE", "YOUR PROD PASS HERE"
    end
    
    if !@ldap.bind
      raise "CONNECTION FAILURE"
    end
  end
  
  def get_operation_result
    ldap.get_operation_result
  end
  
  
  # SEARCHING =================================
  
  ATTR_ARRAY = ["LIST", "ALL", "ATTRS","HERE"] # READING
  MODIFY_OKAY = ["OKAY", "ATTRS", "TO", "MODIFY"] # UPDATING
  
  def fetch(treebase="BASE OF TREE HERE", attrs = ATTR_ARRAY)
    records = []
    ldap.search(:base => treebase, :attributes => attrs, :return_result => false) do |entry|
      records << entry
    end
    records.flatten
  end
  
  def deep_fetch(cn)
    filtr = Net::LDAP::Filter.eq("cn", cn)
    base_fetch(filtr)
  end
  
  def deep_fetch_by_name(first_name, last_name)
    filtr1 = Net::LDAP::Filter.contains("fullname", first_name)
    filtr2 = Net::LDAP::Filter.contains("fullname", last_name)
    filtr = Net::LDAP::Filter.join(filtr1, filtr2)
    base_fetch(filtr)
  end
  
  def base_fetch(filtr)
    records = []
    ldap.search(:base => "BASE OF TREE HERE", :filter => filtr, :attributes => ATTR_ARRAY, :return_result => false) do |entry|
      next if entry.dn =~ /InactiveUsers/
      next if entry.objectclass.include?("alias")
      records << entry
    end
    records.flatten
  end
  
  # MODIFIERS =================================
  
  def swap(dn, att, val)
    if !MODIFY_OKAY.include?(att) # safety net to protect other attributes from modification
      puts "Attempted modification of unauthorized attribute"
      return false
    else
      ldap.replace_attribute(dn, att, val)
    end
  end
  
  def add_attr(dn, att, val)
    if !MODIFY_OKAY.include?(att) # safety net to protect other attributes from modification
      puts "Attempted modification of unauthorized attribute"
      return false
    else
      ldap.add_attribute(dn, att, val)
    end
  end
  
  def delete_attr(dn, att)
    if !MODIFY_OKAY.include?(att) # safety net to protect other attributes from modification
      puts "Attempted modification of unauthorized attribute"
      return false
    else
      ldap.delete_attribute(dn, att)
    end
  end
  
  def self.create_or_update_attribute(ldap, record, arg, att)
    return if (record.respond_to?(att) && record.send(att.intern).first == arg.to_s)
    if record.respond_to?(att)
      ldap.swap(record.dn, att, arg.to_s) 
      puts "UPDATING #{arg}"
    else
      ldap.add_attr(record.dn, att, arg.to_s)
      puts "ADDING #{arg}"
    end
  end

  # USED FOR TESTING ONLY =================================
  
  def raw_search(treebase="BASE OF TREE HERE", attrs = [])
    ldap.search(:base => treebase, :attributes => attrs, :return_result => false) do |entry|
      puts "DN: #{entry.dn}"
      entry.each do |attr, values|
        puts ".......#{attr}:"
        values.each do |value|
          puts "          #{value}"
        end
      end
    end
  end
  
  def method_missing(method)
    if ldap.respond_to?(method)
      ldap.send(method.to_s)
    else
      super
    end
  end
  
  # DOCS: http://net-ldap.rubyforge.org
  
end