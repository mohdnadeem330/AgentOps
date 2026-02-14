import { LightningElement, wire, api } from 'lwc';
import accountKYCCheck from '@salesforce/apex/ALD_AccountController.accountKYCExpiryCheck';

export default class AldAccountKycIndicator extends LightningElement {
    @api recordId;
    error;
    data;

    @wire(accountKYCCheck, { recordId: '$recordId' })
    kycFlag({ error, data }) {
        if (error) {
            this.error = error.body.message;
            this.data = undefined;
        } else if (data) {
            this.error = undefined;
            this.data = data;
            console.log(data);
            
            this.data = this.data.map((item, index) => {
                return { 
                    ...item, 
                    key: item.key + ':', 
                    flagstyle: '', 
                    isLeftColumn: index % 2 === 0 
                };
            
            });
            /*let docsNameWithFlag = [];
            console.log('data',data);
            let iii = 1;
            for(let docName in data) {
                let iconName = data[docName] == 'Green' ? "utility:error" : data[docName] == 'Red' ? "utility:error" : data[docName] == 'Orange' ? "utility:warning" : "utility:Success";
                let alternativeText = docName;
                let variant = iconName.substring(iconName.indexOf(':')+1,iconName.length);
                let title = docName;
                docsNameWithFlag.push({'DocName':docName+' Status - ', 'Flag':data[docName], 'iconName':iconName, 'alternativeText':alternativeText,
                'variant':variant, 'title':title, 'SNo':iii});
                iii++;
            }
            this.docsNameWithFlag = docsNameWithFlag;*/
        }
    }
    // get setMargin(){
    //     margin-top: -12 px;
       
    // }
}