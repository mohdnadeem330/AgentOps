global class CustomerUnitContractStatusScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        CustomerUnitContractStatusBatch batch = new CustomerUnitContractStatusBatch();
        Database.executeBatch(batch, 200); // Batch size optimized for related records
    }
}