import { LightningElement,api, wire,track } from 'lwc';
import getWrapperData from '@salesforce/apex/ECSS_CaseMilestoneController.milestoneDetails';
import getTotalResolution from '@salesforce/apex/ECSS_CaseMilestoneController.getCaseTotalResolution';
const columns = [
     { label: 'Escalation Name', fieldName: 'EscalationName', type: 'text',
     cellAttributes: {
        style: 'white-space: normal; word-wrap: break-word; overflow-wrap: break-word; max-width: 300px;',
    },
},
    { label: 'Target Date', fieldName: 'TargetDate', type: 'DateTime',
     cellAttributes: {
        style: 'white-space: normal; word-wrap: break-word; overflow-wrap: break-word; max-width: 300px;',
    },
},
    { label: 'Target Response In Hrs', fieldName: 'TargetResponseInHrs', type: 'number' ,
     cellAttributes: {
        style: 'white-space: normal; word-wrap: break-word; overflow-wrap: br  eak-word; max-width: 300px;',
    },
},
    { label : 'Escalation Email' , fieldName:'EscalationEmail', type: 'text',          
       cellAttributes: {
        style: 'white-space: normal; word-wrap: break-word; overflow-wrap: break-word; max-width: 300px;',
    },
}
];

export default class ECSS_MilestoneDetails extends LightningElement {
@api recordId;
    data = [];
    totalResolution;
    columns = columns;
    error;
@wire(getWrapperData,{ inpCaseId: '$recordId' })
wiredCustomerUnits({ error, data }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }
@wire(getTotalResolution,{caseId: '$recordId' })
wiredTotalResolution({ error, data }) {
    console.log('Resolution:',data);
        if (data) {
            this.totalResolution = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.totalResolution = null;
        }
    }
}