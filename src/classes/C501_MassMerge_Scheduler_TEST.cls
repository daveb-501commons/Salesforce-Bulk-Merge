@istest
class C501_MassMerge_Scheduler_TEST {

    public static String CRON_EXP = '0 0 0 3 9 ? 2022';

    static testmethod void C501_MassMerge_Scheduler_TEST_Schedule() {

        Test.startTest();

        Account account1 = new Account(
            Name = 'Account1',
            BillingStreet = '123 Street',
            Phone = '(123) 456-7890'
        );
        insert account1;

        Account account2 = new Account(
            Name = 'Account2',
            BillingStreet = '123 Street',
            Phone = '(123) 456-7890'
        );
        insert account2;

        // Schedule the test job
        String jobId = System.schedule('testBasicScheduledApex',
        C501_MassMerge_Scheduler_TEST.CRON_EXP, 
            new C501_MassMerge_Scheduler());

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
            NextFireTime
            FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(C501_MassMerge_Scheduler_TEST.CRON_EXP, 
            ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        System.assertEquals('2022-09-03 00:00:00', 
            String.valueOf(ct.NextFireTime));

        System.assert(
            100.0 == [SELECT Id, Merge_Confidence__c FROM C501_Account_Merge__c].Merge_Confidence__c);

        Test.stopTest();

        System.assert(
            100.0 == [SELECT Id, Merge_Confidence__c FROM C501_Account_Merge__c].Merge_Confidence__c);
   }
}