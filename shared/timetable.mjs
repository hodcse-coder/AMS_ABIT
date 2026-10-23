export const offlineTimetableItems=[
 {key:'timetable-faculty',label:'Faculty Wise Timetable'},
 {key:'timetable-load',label:'Faculty Academic Load'},
 {key:'timetable-available',label:'Faculty Search (Without Load)'},
 {key:'timetable-room-view',label:'Room Wise Timetable'},
 {key:'timetable-floor',label:"Floor Manager's View"}
];
export const timetableMenuItems=[{key:'timetable-offline',label:'Offline Timetable',children:offlineTimetableItems},{key:'timetable-mine',label:'My Offline Timetable'},{key:'timetable-manage',label:'Manage Timetable'},{key:'timetable-rooms',label:'Manage Class Rooms'}];
export const timetablePages=[...offlineTimetableItems,...timetableMenuItems];
export const timetableDays=['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
export function timetableToday(){const parts=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Kolkata',year:'numeric',month:'2-digit',day:'2-digit'}).formatToParts(new Date());return ['year','month','day'].map(key=>parts.find(part=>part.type===key).value).join('-');}
