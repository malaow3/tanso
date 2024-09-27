(()=>{"use strict";var e={},t={};function s(i){var n=t[i];if(void 0!==n)return n.exports;var r=t[i]={exports:{}};return e[i](r,r.exports,s),r.exports}function i(e){return"string"!=typeof e&&"number"!=typeof e?"":(""+e).toLowerCase().replace(/[^a-z0-9]+/g,"")}s.rv=function(){return"1.0.0-beta.2"},s.ruid="bundler=rspack@1.0.0-beta.2";var n={hp:"HP",atk:"Atk",def:"Def",spa:"SpA",spd:"SpD",spe:"Spe"},r=Object.keys(n),a={HP:"hp",hp:"hp",Attack:"atk",Atk:"atk",atk:"atk",Defense:"def",Def:"def",def:"def","Special Attack":"spa",SpA:"spa",SAtk:"spa",SpAtk:"spa",spa:"spa",Special:"spa",spc:"spa",Spc:"spa","Special Defense":"spd",SpD:"spd",SDef:"spd",SpDef:"spd",spd:"spd",Speed:"spe",Spe:"spe",Spd:"spe",spe:"spe"},l=new class{pack(e){return l.packSet(e)}packSet(e){let t="";t+=e.name||e.species;let s=v(e.species);t+="|"+(v(e.name||e.species)===s?"":s)+("|"+v(e.item))+("|"+(v(e.ability)||"-"));let i="";if(t+="|",e.moves)for(let s=0;s<e.moves.length;s++){let n=v(e.moves[s]);(!s||n)&&(t+=(s?",":"")+n,"HiddenPower"===n.substr(0,11)&&n.length>11&&(i=n.slice(11)))}t+="|"+(e.nature||"");let n="|";e.evs&&(n="|"+(e.evs.hp||"")+","+(e.evs.atk||"")+","+(e.evs.def||"")+","+(e.evs.spa||"")+","+(e.evs.spd||"")+","+(e.evs.spe||"")),"|,,,,,"===n?t+="|":t+=n,e.gender?t+="|"+e.gender:t+="|";let r=t=>"ivs"in e&&31!==e.ivs[t]&&void 0!==e.ivs[t]?e.ivs[t].toString():"",a="|";e.ivs&&(a="|"+r("hp")+","+r("atk")+","+r("def")+","+r("spa")+","+r("spd")+","+r("spe")),"|,,,,,"===a?t+="|":t+=a,e.shiny?t+="|S":t+="|",e.level&&100!==e.level?t+="|"+e.level:t+="|",void 0!==e.happiness&&255!==e.happiness?t+="|"+e.happiness:t+="|";let l=void 0!==e.dynamaxLevel&&10!==e.dynamaxLevel;return(e.pokeball||e.hpType&&!i||e.gigantamax||l||e.teraType)&&(t+=","+(e.hpType||"")+(","+v(e.pokeball||""))+(","+(e.gigantamax?"G":""))+(","+(l?e.dynamaxLevel:""))+(","+(e.teraType||""))),t}exportSet(e,t){var s,i,a,l,o,p,u,d;let v="",m=e.species||e.name||"";if(m=(null==(s=null==t?void 0:t.species.get(m))?void 0:s.name)||m,e.name&&e.name!==m?v+=""+e.name+" ("+m+")":v+=""+m,(!t||t.gen>=2)&&("M"===e.gender&&(v+=" (M)"),"F"===e.gender&&(v+=" (F)")),e.item&&(v+=" @ "+(null!=(a=null==(i=null==t?void 0:t.items.get(e.item))?void 0:i.name)?a:e.item)),v+="  \n",e.ability&&(!t||(null==t?void 0:t.gen)>=3)&&(v+="Ability: "+(null!=(o=null==(l=null==t?void 0:t.abilities.get(e.ability))?void 0:l.name)?o:e.ability)+"  \n"),e.level&&100!==e.level&&(v+="Level: "+e.level+"  \n"),e.shiny&&(!t||t.gen>=2)&&(v+="Shiny: Yes  \n"),"number"==typeof e.happiness&&255!==e.happiness&&!isNaN(e.happiness)&&(!t||t.gen>=2)&&(v+="Happiness: "+e.happiness+"  \n"),e.pokeball&&(v+="Pokeball: "+e.pokeball+"  \n"),e.hpType&&(v+="Hidden Power: "+e.hpType+"  \n"),"number"==typeof e.dynamaxLevel&&10!==e.dynamaxLevel&&!isNaN(e.dynamaxLevel)&&(v+="Dynamax Level: "+e.dynamaxLevel+"  \n"),e.gigantamax&&(v+="Gigantamax: Yes  \n"),e.teraType){let s=null==t?void 0:t.species.get(m);v+="Tera Type: "+((null==s?void 0:s.forceTeraType)||e.teraType||(null==(p=null==s?void 0:s.types)?void 0:p[0]))+"  \n"}let c=!0;if(e.evs&&(!t||t.gen>=3))for(let t of r)e.evs[t]&&(c?(v+="EVs: ",c=!1):v+=" / ",v+=""+e.evs[t]+" "+n[t]);if(!c&&(v+="  \n"),e.nature&&(!t||t.gen>=3)&&(v+=""+e.nature+" Nature  \n"),c=!0,e.ivs){let s,i=!0;if(e.moves){for(let n of e.moves)if(s=f(n)){let n=h(s,t);if(!n)continue;for(let t of r)if((void 0===e.ivs[t]?31:e.ivs[t])!==(n[t]||31)){i=!1;break}}}if(i&&!s){for(let t of r)if(31!==e.ivs[t]&&void 0!==e.ivs[t]){i=!1;break}}if(!i)for(let t of r){if(!(void 0===e.ivs[t]||isNaN(e.ivs[t]))&&31!==e.ivs[t])c?(v+="IVs: ",c=!1):v+=" / ",v+=""+e.ivs[t]+" "+n[t]}}if(!c&&(v+="  \n"),e.moves)for(let s of e.moves)s&&(v+="- "+function(e){return"Hidden Power ["===e.substr(0,14)?e:"Hidden Power "===e.substr(0,13)?e.substr(0,13)+"["+e.substr(13)+"]":"hiddenpower"===e.substr(0,11)?"Hidden Power ["+e.substr(11,1).toUpperCase()+e.substr(12)+"]":e}(s=null!=(d=null==(u=null==t?void 0:t.moves.get(s))?void 0:u.name)?d:s)+"  \n");return v+="\n"}unpack(e,t){return l.unpackSet(e,t)}unpackSet(e,t){return p(e,0,0,t).set}importSet(e,t){return d(e.split("\n"),0,t).set}toJSON(e){return JSON.stringify(e)}fromJSON(e){if(e.startsWith("{")&&e.endsWith("}"))return JSON.parse(e)}toString(e,t){return l.exportSet(e,t)}fromString(e){return l.importSet(e)}canonicalize(e,t){var s,n,a;let l=t.species.get(e.species);e.species=i(l.battleOnly?l.baseSpecies:l.name),e.name=void 0,e.item=t.gen>=2&&e.item?i(e.item):void 0,e.ability=t.gen>=3?i(e.ability?e.ability:l.abilities[0]):void 0,e.gender=t.gen>=2&&e.gender&&e.gender!==l.gender?e.gender:void 0,e.level=e.level||100;let o=!0;if(e.ivs)for(let i of r)e.ivs[i]=null!=(s=e.ivs[i])?s:31,t.gen<3&&(e.ivs[i]=function(e){return 2*e+1}(b(e.ivs[i]))),31!==e.ivs[i]&&(o=!1);else e.ivs={hp:31,atk:31,def:31,spa:31,spd:31,spe:31};let p=t.gen<3?void 0:t.natures.get(e.nature||"serious");e.nature=p&&i(p.name);let u=e.hpType,d="",f=!1,v=[];for(let s of e.moves){let n=i(s);if("return"===n||"frustration"===n)d=n;else if("swordsdance"===n)f=!0;else if(n.startsWith("hiddenpower")){if("hiddenpower"===n){let s=e.hpType||function(e,t){let s=(e,t=0)=>t?(e>>>0)%2**t:e>>>0,i={hp:31,atk:31,def:31,spe:31,spa:31,spd:31};if(e<=2){let e=s(t.atk/2),i=s(t.def/2),n=s(t.spe/2),r=s(t.spa/2);return{type:g[e%4*4+i%4],power:s((5*((r>>3)+2*(n>>3)+4*(i>>3)+8*(e>>3))+r%4)/2+31)}}{let n=0,r=0,a=1;for(let e in i)n+=a*(t[e]%2),r+=a*(s(t[e]/2)%2),a*=2;return{type:g[s(15*n/63)],power:e<6?s(40*r/63)+30:60}}}(t.gen,e.ivs).type;n=`${n}${s}`}else u=n.substr(11,1).toUpperCase()+n.substr(12)}v.push(n)}e.moves=v.sort((e,t)=>e.localeCompare(t));let m=t.species.get(e.species).baseStats;for(let s of(e.evs=e.evs||{},r))if(t.gen<3)e.evs[s]=null!=(n=e.evs[s])?n:252;else if(e.evs[s]){let i=function(e,t,s,i=31,n,r=100,a){if(void 0===n&&(n=e<3?252:0),e<3&&(i=2*b(i),a=void 0),"hp"===t)return 1===s?s:y(y(2*s+i+y(n/4)+100)*r/100+10);{let e=y(y(2*s+i+y(n/4))*r/100+5);if(void 0!==a){if(a.plus===t)return y(y(110*e,16)/100);if(a.minus===t)return y(y(90*e,16)/100)}return e}}(t.gen,s,m[s],e.ivs[s],e.evs[s],e.level,p);if("hp"===s)e.evs[s]=1===m[s]?0:Math.max(0,(Math.ceil((i-e.level-10)*100/e.level)-2*m[s]-e.ivs[s])*4);else{let t=p?p.plus===s?1.1:p.minus===s?.9:1:1;e.evs[s]=Math.max(0,(Math.ceil((Math.ceil(i/t)-5)*100/e.level)-2*m[s]-e.ivs[s])*4)}}else e.evs[s]=0;if(2===t.gen&&"marowak"===e.species&&"thickclub"===e.item&&f&&100===e.level){let t=2*Math.floor(e.ivs.atk/2);for(;e.evs.atk>0&&160+t+Math.floor(e.evs.atk/4)+5>255;)e.evs.atk-=4}let h=t.gen>=7&&100===e.level;if(u&&o){let s=2===t.gen?c[u].dvs:c[u].ivs;for(let i of r)2===t.gen?e.ivs[i]=i in s?function(e){return 2*e+1}(s[i]):31:!h&&(e.ivs[i]=null!=(a=s[i])?a:31);2===t.gen&&(e.ivs.hp=function(e){return 2*e+1}(function(e){return b(void 0===e.atk?31:e.atk)%2*8+b(void 0===e.def?31:e.def)%2*4+b(void 0===e.spe?31:e.spe)%2*2+b(void 0===e.spa?31:e.spa)%2}(e.ivs)))}return e.hpType=u&&h?u:void 0,"return"===d?e.happiness=255:"frustration"===d?e.happiness=0:e.happiness=void 0,e.shiny=t.gen>=2&&e.shiny?e.shiny:void 0,e.pokeball=void 0,e.dynamaxLevel=8===t.gen?e.dynamaxLevel:void 0,e.gigantamax=8===t.gen&&e.gigantamax?e.gigantamax:void 0,e.teraType=9===t.gen?e.teraType:void 0,e}},o=["","0","1","H","S"];function p(e,t=0,s=0,i){let n;let r={};if((s=e.indexOf("|",t))<0)return{i:t,j:s};if(r.name=e.substring(t,s),t=s+1,(s=e.indexOf("|",t))<0)return{i:t,j:s};if(r.species=m(e.substring(t,s),null==i?void 0:i.species)||r.name,t=s+1,(s=e.indexOf("|",t))<0)return{i:t,j:s};if(r.item=m(e.substring(t,s),null==i?void 0:i.items),t=s+1,(s=e.indexOf("|",t))<0)return{i:t,j:s};let a=m(e.substring(t,s),null==i?void 0:i.abilities);if("-"===a)a="";else if(o.includes(a)){if(i){let e=i.species.get(r.species);(null==e?void 0:e.baseSpecies)==="Zygarde"&&"H"===a?a="Power Construct":(null==e?void 0:e.abilities)&&(a=e.abilities[a||"0"])}if(""!==a&&!a)return{i:t,j:s}}if(r.ability=a,t=s+1,(s=e.indexOf("|",t))<0)return{i:t,j:s};if(r.moves=e.substring(t,s).split(",",24).filter(e=>e).map(e=>m(e,null==i?void 0:i.moves)),t=s+1,(s=e.indexOf("|",t))<0)return{i:t,j:s};if(r.nature=m(e.substring(t,s),null==i?void 0:i.natures),t=s+1,(s=e.indexOf("|",t))<0)return{i:t,j:s};if(r.evs={hp:0,atk:0,def:0,spa:0,spd:0,spe:0},s!==t){let i=e.substring(t,s);if(i.length>5){let e=i.split(",");r.evs.hp=Number(e[0])||r.evs.hp,r.evs.atk=Number(e[1])||r.evs.atk,r.evs.def=Number(e[2])||r.evs.def,r.evs.spa=Number(e[3])||r.evs.spa,r.evs.spd=Number(e[4])||r.evs.spd,r.evs.spe=Number(e[5])||r.evs.spe}}if(t=s+1,(s=e.indexOf("|",t))<0)return{i:t,j:s};if(t!==s&&(r.gender=e.substring(t,s)),t=s+1,(s=e.indexOf("|",t))<0)return{i:t,j:s};if(r.ivs={hp:31,atk:31,def:31,spa:31,spd:31,spe:31},s!==t){let i=e.substring(t,s).split(",",6);r.ivs.hp=""===i[0]?31:Number(i[0])||0,r.ivs.atk=""===i[1]?31:Number(i[1])||0,r.ivs.def=""===i[2]?31:Number(i[2])||0,r.ivs.spa=""===i[3]?31:Number(i[3])||0,r.ivs.spd=""===i[4]?31:Number(i[4])||0,r.ivs.spe=""===i[5]?31:Number(i[5])||0}return(t=s+1,(s=e.indexOf("|",t))<0)?{i:t,j:s}:(t!==s&&(r.shiny=!0),t=s+1,(s=e.indexOf("|",t))<0)?{i:t,j:s}:(t!==s&&(r.level=parseInt(e.substring(t,s))),t=s+1,(s=e.indexOf("]",t))<0?t<e.length&&(n=e.substring(t).split(",",6)):t!==s&&(n=e.substring(t,s).split(",",6)),n&&(r.happiness=n[0]?Number(n[0]):255,r.hpType=n[1]||"",r.pokeball=m(n[2]||"",null==i?void 0:i.items),r.gigantamax=!!n[3],r.dynamaxLevel=n[4]?Number(n[4]):10,r.teraType=n[5]||""),{set:r,i:t,j:s})}var u=/^[A-Za-z]+ (N|n)ature/;function d(e,t=0,s){var n,r,l,o;let p;for(;t<e.length;t++){let d=e[t].trim();if(""===d||"---"===d||"==="===d.substr(0,3)||d.includes("|"))return{set:p,line:t};if(p){if("Trait: "===d.substr(0,7))d=d.substr(7),p.ability=d;else if("Ability: "===d.substr(0,9))d=d.substr(9),p.ability=d;else if("Shiny: Yes"===d)p.shiny=!0;else if("Level: "===d.substr(0,7))d=d.substr(7),p.level=+d;else if("Happiness: "===d.substr(0,11))d=d.substr(11),p.happiness=+d;else if("Pokeball: "===d.substr(0,10))d=d.substr(10),p.pokeball=d;else if("Hidden Power: "===d.substr(0,14))d=d.substr(14),p.hpType=d;else if("Tera Type: "===d.substr(0,11))d=d.substr(11),p.teraType=d;else if("Dynamax Level: "===d.substr(0,15))d=d.substr(15),p.dynamaxLevel=+d;else if("Gigantamax: Yes"===d)p.gigantamax=!0;else if("EVs: "===d.substr(0,5)){let e=(d=d.substr(5)).split(" / ");for(let t of(p.evs={hp:0,atk:0,def:0,spa:0,spd:0,spe:0},e)){let e=t.indexOf(" ");if(-1===e)continue;let s=a[t.substr(e+1)],i=parseInt(t.substr(0,e));s&&(p.evs[s]=i)}}else if("IVs: "===d.substr(0,5)){let e=(d=d.substr(5)).split(" / ");for(let t of(p.ivs={hp:31,atk:31,def:31,spa:31,spd:31,spe:31},e)){let e=t.indexOf(" ");if(-1===e)continue;let s=a[t.substr(e+1)],i=parseInt(t.substr(0,e));s&&(isNaN(i)&&(i=31),p.ivs[s]=i)}}else if(u.exec(d)){let e=d.indexOf(" Nature");-1===e&&(e=d.indexOf(" nature")),"undefined"!==(d=d.substr(0,e))&&(p.nature=d)}else if("-"===d.substr(0,1)||"~"===d.substr(0,1)){" "===(d=d.substr(1)).substr(0,1)&&(d=d.substr(1)),!p.moves&&(p.moves=[]);let e=f(d);if(e){d="Hidden Power "+e.toString();let t=h(e,s);if(!p.ivs&&t){let e;for(e in p.ivs={hp:31,atk:31,def:31,spa:31,spd:31,spe:31},t)p.ivs[e]=t[e]}}"Frustration"===d&&void 0===p.happiness&&(p.happiness=0),p.moves.push(d)}}else{p={name:"",species:"",gender:""};let e=d.lastIndexOf(" @ ");-1!==e&&(p.item=d.substr(e+3),"noitem"===i(p.item)&&(p.item=""),d=d.substr(0,e))," (M)"===d.substr(d.length-4)&&(p.gender="M",d=d.substr(0,d.length-4))," (F)"===d.substr(d.length-4)&&(p.gender="F",d=d.substr(0,d.length-4));let t=d.lastIndexOf(" (");if(")"===d.substr(d.length-1)&&-1!==t){let e=(d=d.substr(0,d.length-1)).substr(t+2);p.species=null!=(r=null==(n=null==s?void 0:s.species.get(e))?void 0:n.name)?r:e,d=d.substr(0,t),p.name=d}else p.species=null!=(o=null==(l=null==s?void 0:s.species.get(d))?void 0:l.name)?o:d,p.name=""}}return{set:p,line:t+1}}function f(e){return"Hidden Power ["===e.substr(0,14)?e.substr(14,e.length-15):"Hidden Power "===e.substr(0,13)?e.substr(13):"hiddenpower"===e.substr(0,11)?e.substr(11,1).toUpperCase()+e.substr(12):void 0}function v(e){return e?e.replace(/[^A-Za-z0-9]+/g,""):""}function m(e,t){if(!e)return"";if(t){let s=t.get(e);if(null==s?void 0:s.exists)return s.name}return e.replace(/([0-9]+)/g," $1 ").replace(/([A-Z])/g," $1").replace(/[ ][ ]/g," ").trim()}var c={Bug:{ivs:{atk:30,def:30,spd:30},dvs:{atk:13,def:13}},Dark:{ivs:{},dvs:{}},Dragon:{ivs:{atk:30},dvs:{def:14}},Electric:{ivs:{spa:30},dvs:{atk:14}},Fighting:{ivs:{def:30,spa:30,spd:30,spe:30},dvs:{atk:12,def:12}},Fire:{ivs:{atk:30,spa:30,spe:30},dvs:{atk:14,def:12}},Flying:{ivs:{hp:30,atk:30,def:30,spa:30,spd:30},dvs:{atk:12,def:13}},Ghost:{ivs:{def:30,spd:30},dvs:{atk:13,def:14}},Grass:{ivs:{atk:30,spa:30},dvs:{atk:14,def:14}},Ground:{ivs:{spa:30,spd:30},dvs:{atk:12}},Ice:{ivs:{atk:30,def:30},dvs:{def:13}},Poison:{ivs:{def:30,spa:30,spd:30},dvs:{atk:12,def:14}},Psychic:{ivs:{atk:30,spe:30},dvs:{def:12}},Rock:{ivs:{def:30,spd:30,spe:30},dvs:{atk:13,def:12}},Steel:{ivs:{spd:30},dvs:{atk:13}},Water:{ivs:{atk:30,def:30,spa:30},dvs:{atk:14,def:13}}},g=["Fighting","Flying","Poison","Ground","Rock","Bug","Ghost","Steel","Fire","Water","Grass","Electric","Psychic","Ice","Dragon","Dark"];function h(e,t){let s=c[e];if(s)return(null==t?void 0:t.gen)===2?function(e){let t;let s={};for(t in e)s[t]=k(e[t]);return s}(s.dvs):s.ivs}function b(e){return Math.floor(e/2)}function k(e){return 2*e+1}var y=(e,t=0)=>t?(e>>>0)%2**t:e>>>0,S=class e{constructor(e,t,s,i,n){this.team=e,this.data=t,this.format=s,this.name=i,this.folder=n,this.team=e,this.format=s,this.name=i,this.folder=n,this.data=t,s&&(null==t?void 0:t.forGen)&&("gen"===s.slice(0,3)?this.data=t.forGen(parseInt(s[3])):(this.format=`gen6${s}`,this.data=t.forGen(6)))}get gen(){var e;return null==(e=this.data)?void 0:e.gen}pack(){return x.packTeam(this)}static unpack(e,t){return x.unpackTeam(e,t)}export(e){let t="";for(let s of this.team)t+=l.exportSet(s,e||this.data);return t}static import(e,t){return x.importTeam(e,t)}toString(e){return this.export(e)}static fromString(e,t){let s=x.importTeams(e,t,!0,!0);return s.length?s[0]:void 0}toJSON(){return JSON.stringify(this.team)}static fromJSON(t){if("["===t.charAt(0)&&"]"===t.charAt(t.length-1))return new e(JSON.parse(t))}static canonicalize(e,t){let s;let i=[];for(let n of e){let e=l.canonicalize(n,t);s?i.push([e.species,e]):s=e}return[s,...i.sort((e,t)=>e[0].localeCompare(t[0])).map(([,e])=>e)]}},x=new class{packTeam(e){let t="";for(let s of e.team)t&&(t+="]"),t+=l.packSet(s);return t}unpackTeam(e,t){if(!e)return;if("["===e.charAt(0)&&"]"===e.charAt(e.length-1))return S.fromJSON(e);let s=[],i=0,n=0;for(let r=0;r<24;r++){let r=p(e,i,n,t);if(!r.set)return;if(s.push(r.set),i=r.i,(n=r.j)<0)break;i=n+1}return new S(s,t)}importTeam(e,t){let s=x.importTeams(e,t,!0);return s.length?s[0]:void 0}importTeams(e,t,s,i){let n=e.split("\n");if(1===n.length||2===n.length&&!n[1]){let e=i?w(n[0],t):x.unpackTeam(n[0],t);return e?[e]:[]}let r=[],a=-1,l=[];for(let e=0;e<n.length;e++){let i=n[e].trim();if("==="===i.substr(0,3)){if(s&&r.length)return r;l=[],i=i.substr(3,i.length-6).trim();let e=`gen${(null==t?void 0:t.gen)||9}`,n=i.indexOf("]");n>=0&&(e=i.substr(1,n-1),i=i.substr(n+1).trim());let a=i.lastIndexOf("/"),o="";a>0&&(o=i.slice(0,a),i=i.slice(a+1)),r.push(new S(l,t,e,i,o))}else if(i.includes("|")){let e=w(i,t);e&&r.push(e)}else if(a!==e){let s=d(n,e,t);if(s.set&&l.push(s.set),s.line===e)continue;e=(a=s.line)-1}}return l.length&&!r.length&&r.push(new S(l,t)),r}exportTeams(e,t){let s="",i=0;for(let n of e)s+="=== "+(n.format?"["+n.format.toString()+"] ":"")+(n.folder?""+n.folder+"/":"")+(n.name||"Untitled "+ ++i)+" ===\n\n"+n.export(t)+"\n";return s}toString(e,t){return x.exportTeams(e,t)}fromString(e,t){return x.importTeams(e,t,!1,!0)}};function w(e,t){let s=e.indexOf("|");if(s<0)return;let i=e.indexOf("]");i>s&&(i=-1);let n=e.lastIndexOf("/",s);n<0&&(n=i);let r=i>0?e.slice(0,i):`gen${(null==t?void 0:t.gen)||9}`,a=x.unpackTeam(e.slice(s+1),t);return a?new S(a.team,t,r,e.slice(n+1,s),e.slice(i+1,n>0?n:i+1)):a}let N="TANSO";function O(e){console.log(`${N}: ${e}`)}let T=null;function $(){O("Attempting to close the window"),window.close?window.close():(O("Unable to close the window automatically"),alert("Please close this window manually."))}async function I(){let e=arguments.length>0&&void 0!==arguments[0]&&arguments[0];if(!T||T.readyState===WebSocket.CLOSED)(T=new WebSocket("ws://127.0.0.1:11025")).onopen=()=>{O("[open] connection established"),null==T||T.send("[CLIENT] CONNECTION")},T.onmessage=async e=>{O("[message] data received"),O(e.data);try{let s=JSON.parse(e.data);if("close_window"===s.action&&$(),"fetch_teams"===s.action){let e=localStorage.getItem("showdown_teams");e&&(null==T||T.send(JSON.stringify({action:"fetch_teams",data:e}))),!window.document.hasFocus()&&$()}if("load_teams"===s.action||"load_teams_overwrite"===s.action){let e=localStorage.getItem("showdown_teams"),i=s.data,n=[];for(let e of i){let s="";for(let i=0;i<e.mons.length;i++){let n=e.mons[i],r=JSON.stringify(n),a=l.fromJSON(r);if(void 0===a){var t;t=`Failed to parse set: ${JSON.stringify(n)}`,console.error(`${N}: ${t}`);continue}0!==i?(console.log(a),s=`${s}]${l.pack(a)}`):s=`${l.pack(a)}`}null!==e.format?n.push(`${e.format}]${e.name}|${s}`):n.push(`${e.name}|${s}`),O(`Formatted team: ${e.name}`)}O("Formatted all teams");let r="";for(let e of n)r=`${r}
${e}`;e=e&&"load_teams_overwrite"!==s.action?`${r}
${e}`:r,"load_teams_overwrite"===s.action?(localStorage.removeItem("showdown_teams"),localStorage.setItem("showdown_teams",r)):null!==e&&(O("Setting teams"),localStorage.setItem("showdown_teams",e)),null==T||T.send(JSON.stringify({action:"load_teams",data:""}))}}catch(e){O(e)}},T.onclose=()=>{!e&&O("[close] connection closed"),T=null,setTimeout(()=>I(!0),100)},T.onerror=()=>{!e&&O("[error] connection error - Is the desktop app running?"),null==T||T.close()}}(async function e(){O("Starting TANSO Userscript v0.0.1"),I(),setInterval(()=>{(!T||T.readyState===WebSocket.CLOSED)&&I(!0)},100)})()})();