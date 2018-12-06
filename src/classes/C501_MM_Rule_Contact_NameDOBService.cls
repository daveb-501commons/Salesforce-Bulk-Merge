//
// Run Code FROM Developer Console
//  1) Debug -> Open Execute Anonymous Window
//  2) paste code
/*
    C501_MM_Rule_Contact_NameDOBService schedule = new C501_MM_Rule_Contact_NameDOBService();
    schedule.execute(null);
*/
//  3) click Execute
//
// Abort scheduled jobs
/*
    List<CronJobDetail> scheduledJobs = [SELECT Id FROM CronJobDetail WHERE Name like 'Contact_NameDOBService_%'];
    for (CronJobDetail scheduledJob :scheduledJobs) {
        Id jobId = [SELECT Id FROM CronTrigger WHERE CronJobDetailId = :scheduledJob.Id].Id;
        System.abortJob(jobId);
    }
*/
//
// Schedule Code FROM Developer Console
/*
    integer numSchedules = 30;
    for (integer i = 0; i < numSchedules; i++) {
        system.schedule('Contact_NameDOBService_' + String.valueOf(i * 2), '0 ' + String.valueOf(i * 2) + ' * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    }                      

    system.schedule('Contact_NameDOBService_0', '0 0 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_30', '0 30 * * * ?', new C501_MM_Rule_Contact_NameDOBService());

*/

global class C501_MM_Rule_Contact_NameDOBService implements Schedulable {

    global void execute(SchedulableContext SC) {

		//
		// Perform all SOQL Queries outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
		//

        // Get Merge Metric
        List<C501_Merge_Metric__c> mergeMetrics = [SELECT Id, Name, Confidence__c, Enable__c, Total_Merge__c, AutoMerge_Percentage__c FROM C501_Merge_Metric__c WHERE Name = 'Contact_NameDOBService'];
        if (mergeMetrics.isEmpty()) {
            mergeMetrics.add( new C501_Merge_Metric__c (
                Name = 'Contact_NameDOBService',
                Confidence__c = 100.0
            ));

            insert mergeMetrics;
        }

        if (!mergeMetrics[0].Enable__c) {
            return;
        }

        Date dateUnder18 = date.today().addYears(-18);

        // Workbench Disclaimer - add LIMIT 200 when using query in Workbench
		AggregateResult[] allAggregatedByServiceContacts = [
            SELECT Count(C501_Service_Household_Id__r.C501_Household__c),
                C501_Birthdate__c,
                C501_Gender__c,
                C501_FirstName_Initial__c,
                C501_Last_Name__c,
                C501_Service_Household_Id__r.C501_Start_Date__c,
                MAX(C501_Service_Household_Id__r.C501_Household__c)MaxAccountId,
                MIN(C501_Service_Household_Id__r.C501_Household__c)MinAccountId
            FROM C501_Service_Contact__c
            WHERE C501_FirstName_Initial__c <> ''
                and C501_Last_Name__c <> ''
                and C501_Birthdate__c <> null and C501_Birthdate__c < :dateUnder18
                and C501_Service_Household_Id__r.C501_Start_Date__c <> null
                and (NOT C501_Service_Household_Id__r.C501_Program__c like '%Change Request%')
            GROUP BY C501_FirstName_Initial__c,
                C501_Last_Name__c,
                C501_Birthdate__c,
                C501_Gender__c,
                C501_Service_Household_Id__r.C501_Start_Date__c
            HAVING Count(C501_Service_Household_Id__r.C501_Household__c) > 1
            ORDER BY Count(C501_Service_Household_Id__r.C501_Household__c) DESC];

        Map<String, C501_Account_Merge__c> mergeAccounts = new Map<String, C501_Account_Merge__c>();
        String uniqueId, maxId, minId;
        for (AggregateResult result :allAggregatedByServiceContacts)  {

            maxId = result.get('MaxAccountId').toString();
            minId = result.get('MinAccountId').toString();

            if (String.isEmpty(maxId) || String.isEmpty(minId) || maxId == minId) {
                continue;
            }

            uniqueId = mergeMetrics[0].Name + String.valueOf(minId) + String.valueOf(maxId);

            system.debug('*****C501_MM_Rule_Contact_NameDOBService::execute ByContacts Found - maxId: ' + maxId
                + ' minId: ' + minId + ' UniqueId: ' + uniqueId + ' Confidence: ' + mergeMetrics[0].Confidence__c
                + 'MetricId: ' + mergeMetrics[0].Id);

            mergeAccounts.put(uniqueId, new C501_Account_Merge__c(
                Unique_Id__c = uniqueId,
                Merge_Confidence__c = mergeMetrics[0].Confidence__c,
                Account__c = minId,
                Merge_Target_Account__c = maxId,
                Merge_Metric__c = mergeMetrics[0].Id
            ));
        }

        //
		// Perform all DML (Data Manipulation Language) calls (insert, update, merge, delete, restore) outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
        //
		if (!mergeAccounts.isEmpty()) {
			Database.SaveResult[] insertResults = Database.insert(mergeAccounts.values(), false);

            // TBD - Look for anything other than Duplicate Id Error on Unique_Id__c which is expected
		}

        C501_MassMerge_SharedCode c501MassMerge_SharedCode = new C501_MassMerge_SharedCode();

        // Check to AutoMerge
        Integer mergeAutoMergeAttemptsRemaining = 5;            // SOQL Governor LIMIT issue LIMIT merge attempts to 5 because each Merge Attempt is currently 10 SOQL Queries
        if (mergeMetrics[0].AutoMerge_Percentage__c > 0.0) {

            Set<Id> accountsProcessed = new Set<Id>();
            for (C501_Account_Merge__c mergeCandidate : [
                SELECT Id, Account__c, Merge_Target_Account__c, Merge_Confidence__c
                FROM C501_Account_Merge__c
                WHERE Merge_Metric__r.Name = 'Contact_NameDOBService'
                LIMIT 200]) {

                    // Check whether account Id merge already attempted
                    if (accountsProcessed.contains(mergeCandidate.Account__c) || accountsProcessed.contains(mergeCandidate.Merge_Target_Account__c)) {
                        continue;
                    }

                    if (mergeAutoMergeAttemptsRemaining-- <= 0) {
                        break;
                    }

                    accountsProcessed.add(mergeCandidate.Account__c);
                    accountsProcessed.add(mergeCandidate.Merge_Target_Account__c);

                    system.debug('***** AutoMerge - Account__c: ' + mergeCandidate.Account__c + ' Merge_Target_Account__c: ' + mergeCandidate.Merge_Target_Account__c);

                    try {
                        c501MassMerge_SharedCode.AccountsMerge( new List<Account> {
                            new Account(
                                Id = mergeCandidate.Account__c,
                                C501_Merge_Action__c = 'Merge',
                                C501_Merge_Confidence__c = mergeCandidate.Merge_Confidence__c,
                                C501_Merge_Target__c = mergeCandidate.Merge_Target_Account__c,
                                C501_Merge_Metric_Name__c = mergeMetrics[0].Name,
                                C501_Merge_Account__c = mergeCandidate.Id
                            ),
                            new Account(
                                Id = mergeCandidate.Merge_Target_Account__c,
                                C501_Merge_Action__c = 'Merge',
                                C501_Merge_Confidence__c = mergeCandidate.Merge_Confidence__c,
                                C501_Merge_Target__c = mergeCandidate.Merge_Target_Account__c,
                                C501_Merge_Metric_Name__c = mergeMetrics[0].Name,
                                C501_Merge_Account__c = mergeCandidate.Id
                            )
                        } );
                    } catch (Exception e) {
                        // NoOp for now since Sandbox has partial data
                        system.debug('***** Account__c: ' + mergeCandidate.Account__c + ' Merge_Target_Account__c: ' + mergeCandidate.Merge_Target_Account__c);
                        system.debug('General Exception: ' + String.valueOf(e) + '\n\n' + e.getStackTraceString());
                    }
            }

            // Clear out all merge candidates based on processed Ids
            Map<Id, C501_Account_Merge__c> mapAccountMergesDelete = new Map<Id, C501_Account_Merge__c>();
            for (C501_Account_Merge__c mergeRelated : [
                SELECT Id
                FROM C501_Account_Merge__c
                WHERE Account__c in :accountsProcessed or Merge_Target_Account__c in :accountsProcessed]) {
                    mapAccountMergesDelete.put(mergeRelated.Id, mergeRelated);
                }

            if (!mapAccountMergesDelete.isEmpty()) {
                delete mapAccountMergesDelete.values();
            }
        }
   }
}