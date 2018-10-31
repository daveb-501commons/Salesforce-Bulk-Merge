//
// Run Code from Developer Console
//  1) Debug -> Open Execute Anonymous Window
//  2) paste code
//      C501_MassMerge_Rule_Contact_PartialSSDOB schedule = new C501_MassMerge_Rule_Contact_PartialSSDOB();
//      schedule.execute(null);
//  3) click Execute
//

global class C501_MassMerge_Rule_Contact_PartialSSDOB implements Schedulable {

    global void execute(SchedulableContext SC) {

		//
		// Perform all SOQL Queries outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
		//

        // Get Merge Metric
        List<C501_Merge_Metric__c> mergeMetric = [SELECT Id, Total_Merge__c FROM C501_Merge_Metric__c WHERE Name = 'Contact_PartialSS'];
        if (mergeMetric.isEmpty()) {
            mergeMetric.add( new C501_Merge_Metric__c (
                Name = 'Contact_PartialSS'
            ));

            insert mergeMetric;
        }

		AggregateResult[] allAggregatedAccounts = [
            SELECT Count(Id), Birthdate, C501_Partial_Social_Security_Id__c, MAX(AccountId), MIN(AccountId)
            FROM Contact
            Where C501_Partial_Social_Security_Id__c <> '' and Birthdate <> null
            Group By C501_Partial_Social_Security_Id__c, Birthdate
            Having Count(Id) > 1
            Order By Count(Id) DESC
            LIMIT 10];

        Map<String, C501_Account_Merge__c> mergeAccounts = new Map<String, C501_Account_Merge__c>();
        String maxId;
        String minId;
        String uniqueId;
        for (AggregateResult result : allAggregatedAccounts)  {
            maxId = result.get('expr1').toString();
            minId = result.get('expr2').toString();
            uniqueId = String.valueOf(maxId) + String.valueOf(maxId);
            mergeAccounts.put(uniqueId, new C501_Account_Merge__c(
                Unique_Id__c = uniqueId,
                Merge_Confidence__c = 90.0,
                Account__c = minId,
                Merge_Target_Account__c = maxId,
                Merge_Metric__c = mergeMetric[0].Id
            ));
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