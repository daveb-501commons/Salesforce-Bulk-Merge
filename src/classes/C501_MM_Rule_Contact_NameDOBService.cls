//
// Run Code from Developer Console
//  1) Debug -> Open Execute Anonymous Window
//  2) paste code
//      C501_MM_Rule_Contact_NameDOBService schedule = new C501_MM_Rule_Contact_NameDOBService();
//      schedule.execute(null);
//  3) click Execute
//

global class C501_MM_Rule_Contact_NameDOBService implements Schedulable {

    global void execute(SchedulableContext SC) {

		//
		// Perform all SOQL Queries outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
		//

        // Get Merge Metric
        List<C501_Merge_Metric__c> mergeMetrics = [SELECT Id, Name, Confidence__c, Total_Merge__c FROM C501_Merge_Metric__c WHERE Name = 'Contact_NameDOBService'];
        if (mergeMetrics.isEmpty()) {
            mergeMetrics.add( new C501_Merge_Metric__c (
                Name = 'Contact_NameDOBService',
                Confidence__c = 100.0
            ));

            insert mergeMetrics;
        }

		AggregateResult[] allAggregatedByContacts = [
            SELECT Count(Id), Birthdate, C501_FirstName_Initial__c, LastName, MAX(AccountId)MaxAccountId, MIN(AccountId)MinAccountId
            FROM Contact
            Where C501_FirstName_Initial__c <> '' and LastName <> '' and Birthdate <> null
            Group By C501_FirstName_Initial__c, LastName, Birthdate
            Having Count(Id) > 1
            Order By Count(Id) DESC];

		AggregateResult[] allAggregatedByServiceContacts = [
            SELECT Count(Id), C501_Birthdate__c, C501_FirstName_Initial__c, C501_Last_Name__c, C501_Service_Household_Id__r.C501_Start_Date__c, MAX(C501_Service_Household_Id__r.C501_Household__c)MaxAccountId, MIN(C501_Service_Household_Id__r.C501_Household__c)MinAccountId
            FROM C501_Service_Contact__c
            Where C501_FirstName_Initial__c <> '' and C501_Last_Name__c <> '' and C501_Birthdate__c <> null and C501_Service_Household_Id__r.C501_Start_Date__c <> null
            Group By C501_FirstName_Initial__c, C501_Last_Name__c, C501_Birthdate__c, C501_Service_Household_Id__r.C501_Start_Date__c
            Having Count(Id) > 1
            Order By Count(Id) DESC];

        String maxId;
        String minId;
        Set<String> accountsByService = new Set<String>();
        for (AggregateResult result : allAggregatedByServiceContacts)  {
            maxId = result.get('MaxAccountId').toString();
            minId = result.get('MinAccountId').toString();
            system.debug('*****C501_MM_Rule_Contact_NameDOBService::execute ByServiceContacts - maxId: ' + maxId + ' minId: ' + minId);
            accountsByService.add(maxId);
            accountsByService.add(minId);
        }

        Map<String, C501_Account_Merge__c> mergeAccounts = new Map<String, C501_Account_Merge__c>();
        String uniqueId;
        for (AggregateResult result : allAggregatedByContacts)  {
            maxId = result.get('MaxAccountId').toString();
            minId = result.get('MinAccountId').toString();
            system.debug('*****C501_MM_Rule_Contact_NameDOBService::execute ByContacts Check - maxId: ' + maxId + ' minId: ' + minId);

            if (accountsByService.contains(maxId) || accountsByService.contains(minId)) {
                system.debug('*****C501_MM_Rule_Contact_NameDOBService::execute ByContacts Found - maxId: ' + maxId
                    + ' minId: ' + minId + ' UniqueId: ' + uniqueId + ' Confidence: ' + mergeMetrics[0].Confidence__c
                    + 'MetricId: ' + mergeMetrics[0].Id);
                uniqueId = mergeMetrics[0].Name + String.valueOf(minId) + String.valueOf(maxId);
                mergeAccounts.put(uniqueId, new C501_Account_Merge__c(
                    Unique_Id__c = uniqueId,
                    Merge_Confidence__c = mergeMetrics[0].Confidence__c,
                    Account__c = minId,
                    Merge_Target_Account__c = maxId,
                    Merge_Metric__c = mergeMetrics[0].Id
                ));
            }
        }

        //
		// Perform all DML (Data Manipulation Language) calls (insert, update, merge, delete, restore) outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
        //
		if (!mergeAccounts.isEmpty()) {
			Database.SaveResult[] insertResults = Database.insert(mergeAccounts.values(), false);

            // TBD - Look for anything other than Duplicate Id Error on Unique_Id__c which is expected
		}
   }
}