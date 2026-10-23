import React from 'react';

export default function ConfigurationIcon({ name }) {
  const flag = <><path d="M7 28V5m0 2c6-5 10 5 20 0v14c-10 5-14-5-20 0"/><circle cx="7" cy="4" r="1"/></>;
  const paths = {
    country: flag,
    nationality: <>{flag}<path d="M14 8v13m7-12v13M7 14c6-5 10 5 20 0"/></>,
    state: <><path d="m13 3 6 0 1 4 4 2 4-1 3 5-3 3v4l3 3-3 5-4-1-4 2-1 4h-6l-1-4-4-2-4 1-3-5 3-3v-4l-3-3 3-5 4 1 4-2Z" transform="translate(2 0) scale(.86)"/><circle cx="16" cy="16" r="6"/></>,
    city: <><path d="M6 29V3h20v26H6Zm8 0v-7h4v7"/>{[8,13,18].flatMap(y=>[11,16,21].map(x=><path key={`${x}-${y}`} d={`M${x} ${y}h.2v.2h-.2Z`}/ >))}</>,
    organization: <><path d="m2 10 14-7 14 7H2Zm0 18h28M4 24h24M7 12v12m6-12v12m6-12v12m6-12v12"/></>,
    last_passout_institution: <><path d="m2 10 14-7 14 7-14 7L2 10Zm6 4v9c5 5 11 5 16 0v-9m6-4v14"/></>,
    languages: <><path d="m3 8 12-4v22L3 30V8Zm12-4 14 4v22l-14-4M7 11h5m-3-2v3m-3 2 6 7m0-8-6 8m13 2 3-11 4 12m-6-4h5"/></>,
    national_holidays: <><rect x="4" y="7" width="24" height="22" rx="1"/><path d="M4 13h24M10 3v9m12-9v9"/></>,
    document_category: <><path d="M5 22V4h12l5 5v5M17 4v6h5M11 28V14h11l5 5v9H11Zm11-14v6h5M5 22h6"/></>,
    hobbies: <><path d="m16 3 4 9 10 1-8 7 2 10-8-5-9 5 2-10-7-7 10-1 4-9Z"/></>,
  };
  return <svg width="40" height="40" viewBox="0 0 32 32" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name] || flag}</svg>;
}
