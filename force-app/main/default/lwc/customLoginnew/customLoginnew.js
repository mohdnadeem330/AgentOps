import { LightningElement, track, wire } from 'lwc';

import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
export default class CustomLoginnew extends LightningElement {
 logo=resourcesPath+ "/ALDARResources/png/AldarLogo.png";
    //logonew=resourcesPath+ "/ALDARResources/png/AldarLoginLogo.png";
    logonew=resourcesPath+ "/ALDARResources/svg/AldarLoginLogo.svg";
}