import { LightningElement } from 'lwc';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';

export default class SuccessActionModal extends LightningElement {

    passwordSuccessIcon=resourcesPath+"/ALDARResources/svg/PasswordSuccess.svg";

   
    redirectToDashboard(){
        window.open("/s/manage-cases", "_self");
    }
}