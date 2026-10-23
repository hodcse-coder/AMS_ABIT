import React,{useEffect,useRef} from 'react';
export default function HeaderMessage({message}){
 const lane=useRef(null),text=useRef(null);
 useEffect(()=>{if(!lane.current||!text.current)return;const update=()=>{lane.current?.style.setProperty('--message-travel',(lane.current.clientWidth-text.current.scrollWidth)+'px');};update();const observer=new ResizeObserver(update);observer.observe(lane.current);observer.observe(text.current);return()=>observer.disconnect();},[message]);
 return <div className="workspace-message workspace-message-moving" ref={lane} role="status" aria-live="polite"><span ref={text}>{message}</span></div>;
}
