require 'rubygems'
require 'test/unit'
require File.join(File.expand_path(File.dirname(__FILE__)), "wrap_ldap.rb")

class DomLapTest < Test::Unit::TestCase
  
  def ldap_production
    WrapLdap.new(:production)
  end
  
  def ldap
    WrapLdap.new
  end
  
  def test_production_connection
    assert( (ldap.get_operation_result.message == "Success"), "Connection Failed" )
  end
  
  def test_fetch
    person = ldap.fetch("cn=bo,ou=j")
    assert( (ldap.get_operation_result.message == "Success"), "LDAP Query Failure for jmb" )
    assert( (person.first.fullname.first == "Bo Jangles"), "LDAP attribute error" )
  end
  
  def test_production_fetch
    person = ldap.fetch("cn=bo,ou=j")
    assert( (ldap_production.get_operation_result.message == "Success"), "LDAP Query Failure for jmb" )
    assert( (person.first.fullname.first == "Bo Jangles"), "LDAP attribute error" )
  end
  
  def test_deep_fetch
    person = ldap_production.deep_fetch("bo")
    assert( (ldap_production.get_operation_result.message == "Success"), "LDAP Query Failure for jmb" )
    assert( (person.first.fullname.first == "Bo Jangles"), "LDAP attribute error" )
  end
  
  def test_deep_fetch_by_name
    person = ldap_production.deep_fetch_by_name("Bo", "Jangles")
    assert( (ldap_production.get_operation_result.message == "Success"), "LDAP Query Failure for jmb" )
    assert( (person.first.fullname.first == "Bo Jangles"), "LDAP attribute error" )
  end
  
  def test_unauthorized_methods
    %w(rename delete add).each do |method|
      assert( !ldap.send(method), "Unauthorized method attempted" )
    end
  end
  
  def test_swap
    person = ldap.fetch("cn=bo,ou=j")
    assert( !ldap.swap(person.first.dn, "email", "foo"), "Unauthorized attribute update attempted" )
    
    ldap.swap(person.first.dn, "id", "123456789")
    ldap.swap(person.first.dn, "workforceid", "987654321")
    person = ldap.fetch("cn=bo,ou=j")
    
    assert( (person.first.id.first == "123456789"), "Incorrect ID" )
    assert( (person.first.workforceid.first == "987654321"), "Incorrect Workforce ID" )
    
    ldap.swap(person.first.dn, "id", "000")
    ldap.swap(person.first.dn, "workforceid", "000") 
  end
 
end