
@IsTest
public with sharing class LeadProcessorTest {
    @TestSetup
    static void makeData(){
        List<Lead> leads = new List<Lead>();
        for(Integer i =0; i<200;i++){
            leads.add(new Lead(LastName = 'test' + i, Company='Test'+ i));
        }

        Database.insert(leads,true);
    }
    @IsTest
    static void testInsertedLeads(){
        Test.startTest();
        LeadProcessor leadProcessor = new LeadProcessor();
        Id jobId = Database.executeBatch(leadProcessor,200);
        Test.stopTest();


        System.assertEquals(200, [SELECT COUNT() FROM LEAD WHERE LeadSource = :LeadConstants.LEAD_SOURCE_DREAMFORCE]);
        System.assertNotEquals(null, jobId);
        System.assertEquals(0, [SELECT COUNT() FROM LEAD WHERE LeadSource != :LeadConstants.LEAD_SOURCE_DREAMFORCE]);
    }


}