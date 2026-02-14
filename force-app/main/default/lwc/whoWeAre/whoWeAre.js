import { LightningElement } from 'lwc';
import testResource from '@salesforce/resourceUrl/testVideo';
import resourcesPath from '@salesforce/resourceUrl/ALDARResources';
export default class WhoWeAre extends LightningElement {



    testVideo = testResource ;
    icon1=resourcesPath+ "/ALDARResources/svg/KnowYourTeamIcon2.svg";
    icon2=resourcesPath+ "/ALDARResources/svg/KnowYourTeamIcon3.svg";
    icon3=resourcesPath+ "/ALDARResources/svg/KnowYourTeamIcon4.svg";
    icon4=resourcesPath+ "/ALDARResources/svg/KnowYourTeamIcon5.svg";
    icon5=resourcesPath+ "/ALDARResources/svg/KnowYourTeamIcon6.svg";

    kpisArray=[
        {    id:1,
            lable:"Awards reveived",
            value:"100+"
        },
        {    id:2,
            lable:"Homes Delivered",
            value:"36,400+"
        },
        {
            id:3,
            lable:"In progress and planning",
            value:"29,000+"
        }
    ];


    infoCardsArray=[
        {
            id:1,
            icon:this.icon1,
            lable:"No. 1 in tourist safety and security in the world"
        },
        {
            id:2,
            icon:this.icon2,
            lable:"High quality infrastructure"
        },
        {
            id:3,
            icon:this.icon3,
            lable:"World class culture and entertainment"
        },
        {
            id:4,
            icon:this.icon4,
            lable:"International schools and universities"
        },
        {
            id:5,
            icon:this.icon5,
            lable:"Globally renowned medical facilities"
        },
    ];
}