import { LightningElement } from 'lwc';
import getRRAssignmentRecord from '@salesforce/apex/StatusHandlerController.getRRAssignmentRecord';
import getRRAssignmentTeamRecord from '@salesforce/apex/StatusHandlerController.getRRAssignmentTeamRecord';
import updateStatus from '@salesforce/apex/StatusHandlerController.updateStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class StatusHandler extends LightningElement {
    myRecord;
    myTeamsRecords;
    isLoading=true;
    connectedCallback(){
        this.isLoading=true;
        this.initCurrentStatus();
    }
    initCurrentStatus(){
    
        getRRAssignmentRecord()
        .then(data => {
            console.log('---');
            console.log(data);
            if(data.length >0 ){
                this.myRecord=data;
            }else{
                this.myRecord=undefined;
            }
            
            this.isLoading=false;
        })
        .catch(error => {
            console.log('Unable to retrive data data ==>'+ JSON.stringify(error));
            this.myRecord=undefined;
            this.isLoading=false;
        });

        getRRAssignmentTeamRecord()
        .then(data => {
            console.log('---');
            console.log(data);
            if(data.length >0 ){
                this.myTeamsRecords=data;
            }else{
                this.myTeamsRecords=undefined;
            }
            
            this.isLoading=false;
        })
        .catch(error => {
            console.log('Unable to retrive data data ==>'+ JSON.stringify(error));
            this.myTeamsRecords=undefined;
            this.isLoading=false;
        });
    }

    updateAgentStatus(event){
        this.isLoading=true;
        updateStatus({userID:event.target.dataset.userId , isAgentAvaibale : event.target.checked})
        .then(data => {
            this.initCurrentStatus();
        })
        .catch(error => {
            console.log('Unable to save record'+ JSON.stringify(error));
                var errorJSON = JSON.stringify(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errorJSON,
                        variant: 'error'
                    })
                );
                this.isLoading=false;
        });
    }
}