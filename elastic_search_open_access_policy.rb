##
## elastic_search_open_access_policy.rb - John Martinez (john@evident.io)
## Copyright (c) 2017 Evident.io, Inc.
## PROVIDED AS IS WITH NO WARRANTY OR GUARANTEES
##
## Name: Elasticsearch Domain with Open Access Policy
##
## Severity Level: High
##
## Description
## Elasticsearch domains control access via an access policy. This signature checks for
## an access policy with open access.
## 
## Resolution
## Go to the Elasticsearch service in the AWS Console and modify the access policy to
## a specific permission other than a global permission.
## 
configure do |c|
    c.deep_inspection = [:domain_id, :arn, :endpoint, :access_policies]
    c.valid_regions = [:us_east_1, :us_east_2, :us_west_1, :us_west_2, :ap_south_1, :ap_northeast_2,
                        :ap_southeast_1, :ap_southeast_2, :ap_northeast_1, :eu_central_1, 
                        :eu_west_1, :sa_east_1]
    c.unique_identifier  = [:domain_name]
end

def perform(aws)
    domain_names = aws.elastic_search.list_domain_names.domain_names
    
    domain_names.each do |domain_name|
        
        domain_name = domain_name[:domain_name]

        domain_status_list = aws.elastic_search.describe_elasticsearch_domains({
            domain_names: [ domain_name ],
        }).domain_status_list
        
        domain_status_list.each do |domain_status|
            
            policy_doc = nil
            access_policies = nil
            
            domain_id  = domain_status[:domain_id]
            arn = domain_status[:arn]
            endpoint = domain_status[:endpoint]
            policy_doc = domain_status[:access_policies]
            
            fail_count = 0
            
            if policy_doc != ""
                
                access_policies = JSON.parse(URI.decode(policy_doc))
                policy = access_policies.Statement
            
                effect = nil
                principal = nil
                action = nil
                condition = nil
                source_ip = nil

                policy.each do |policy_statement|
                
                    effect = policy_statement["Effect"]
                    principal = policy_statement["Principal"]["AWS"]
                    action = policy_statement["Action"]
                    condition = policy_statement["Condition"]
                
                    if condition != nil && condition.has_key?("IpAddress")
                        source_ip = policy_statement["Condition"]["IpAddress"]["aws:SourceIp"]
                    else
                        source_ip = "N/A"
                    end
                
                    if effect == "Allow" && principal == "*" && action == "es:*" && (source_ip == nil || source_ip == "0.0.0.0/0")
                        fail_count += 1
                    end
                
                end
            
            end

            set_data(domain_id: domain_id, arn: arn, endpoint: endpoint, access_policies: access_policies)

            if fail_count > 0
                fail(message: "Elasticsearch domain #{domain_name} has an open access policy", resource_id: domain_name)
            else
                if access_policies == nil
                    pass(message: "Elasticsearch domain #{domain_name} has no access policies", resource_id: domain_name)
                else
                    pass(message: "Elasticsearch domain #{domain_name} has a restricted access policy", resource_id: domain_name)
                end
            end
            
        end
        
    end

end
