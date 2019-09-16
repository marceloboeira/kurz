# Architecture
> Specification, reasoning behind decisions of architecture, stack and dependencies.

## Index

* [What Is a URL Shortener?](#what-is-a-url-shortener)
* [Why You Should Create You Own?](#why-you-should-create-you-own)
* [Kurz](#kurz)
  * [Goals](#goals)
    * [Non-Goals](#non-goals)
  * [Alternatives](#alternatives)
* [Challenges](#challenges)
  * [Short URL Generation](#short-url-generation)
    * [Traditional Hashing](#traditional-hashing)
      * [Idempotency](#idempotency)
      * [Collision Probabilities](#collision-probabilities)
      * [Length](#length)
      * [The Birthday Paradox](#the-birthday-paradox)
    * [Conclusion](#conclusion)
      * [What are the alternatives then?](#what-are-the-alternatives-then)
      * [Decimal is not safe](#decimal-is-not-safe)
      * [HashID](#hashid)
        * [TL;DR](#tldr)
      * [Sequence Generator](#sequence-generator)
  * [Storage](#storage)
    * [Schema](#schema)
    * [Capacity Planning](#capacity-planning)
      * [Final Estimates](#final-estimates)
        * [Storage Estimate](#storage-estimate)
        * [Cache Estimate](#cache-estimate)
  * [Performance](#performance)
    * [Design](#design)
* [Stack](#stack)

---------------

# What Is a URL Shortener?

A URL Shortener is a service that creates short and easy links from big or complex URL, allowing people to use the alias to be redirected to the original. Such services are, usually, accompanied of statistics of access for each URL, API access and can serve as a unique place to have permanent aliases for common things on your company.

**What is the use**, you might wonder, here are some examples:

* **Compression**
  * e.g.: Twitter, given the limitations of the size of a tweet, the less characters one spends on URL the better.
  * > ... Twitter itself automatically shortens URLs with 30 characters or more - [Source][1]
  * You can also see similar minded tools on messaging platforms, facebook's `fb.me`...
* **Readability**
  * Ads have usually size/space/UX limitations, let's say SMS or even an image with a link.
  * e.g.: `shp.fy/computers` is better than `https://shopify.com/store/25/products/29192381`.
  * Lot's of companies use short links for referrals too, e.g.: `https://foo.bar/ref/marcelob`
* [**Permalinks**][6]
  * Links that likely won't change in the future, for consitency and usability perspectives.
  * e.g.: `spotify.com/faq` or even `spt.fi/faq`.
* **Statistics**
  * e.g: Information of how many people clicked on the link, which browsers they have, where they're from...
* **Standardization**
  * Short and useful internal links is common in companies with lots of employees. Google uses with `go/`, Airbnb `air/`
  * e.g.: `air/git`, `go/referrals`, `air/payslips`

-------

# Why You Should Create You Own?

Mainly, the motivation is learning from the challenges that a URL Shortener can provide.

You can simplify the problem by lowering the requirements, I have [done it myself][9] a while back, it taught me different things at the time as the proprosed challenges were different. I've also had an attempt to make [something a bit faster][15], but with the wrong tools.

As most system-related challenges, by adding scalability and performance as factors, the challenge becomes interesting.

Here are some of the challenges worth exploring:

e.g.:

* Reliability - `How often does the system fails? Under which conditions?`
* Performance - `How fast can we read/write data to it?`
* Data-Durability - `How long are URLs available for?`
* Storage-Capacity - `How many URLs can we store?`
* Scalability - `How/How much can I increase one of the above?`
* Consistency - `Operations can't violate consistency rules`

Among such challenges, I have spared a few and created a priority order. This is something common when designing such applications, given that the mentioned features of a system are usually inversely proportional, or two different sides of the same coin.

e.g.:
* a reliable database, that can never fail, might be really slow to ensure it will never fail.
* a long-term file system for backups might have severe capacity or performance limitations given it must copy data multiple times to ensure its durability.

## Kurz

Kurz was born from an idea, an experimental project with a specific stack, but also to be a study project on high-performant and reliable system design exercise.

### Name meaning

**Kurz** - it is the literal translation of **short** to German. [[more][23]]

### Alternatives

As mentioned, `kurz` is an experimental project, the README should contain more info on the project status.

Here are some alternatives to kurz:

* Open Source:
  * [YOURLS/YOURLS][24]
  * [thedevs-network/kutt][25]
  * [cydrobolt/polr][26]
* Paid alternatives:
  * [bit.ly](https://bit.ly) - Paid service, you can use for free with limitations, paid users can also have their own domain, analytics...
  * [tiny.cc](https://bit.ly) - Similar
  * [cutt.ly](https://cutt.ly) - Similar

### Goals

First let us look at the goals, then discuss in depth what are the exact features we'll be focusing on and the challenges they bring.

* Performance - Fast redirects/reads/writes. e.g.: how fast URL redirection takes?
* Scalability - Ease of scaling reads/writes by adding more instances
* Consistency - Short URLs can't be overriden by new URLs. e.g.: hash collisions.
* UX - Simple to host, to use.
* Reliability - Low percentage of failures when reading/writing/redirecting. e.g.: what if the database goes down?

We'll dive into specifics later on.

#### Non-Goals

* User Management - creating different users to own URLs
* Authentication - creating API specific keys and authentication
* Authorization - given different roles/permissions to users

## Challenges

### Short URL Generation

Given a resonably large URL, say:

```
https://my-long-link.com/a-very-long/path/with/numbers/90999.html
```

We would like to share it in a less verbose format, that being a tweet, a instant message...

When we think about it, it's mainly a hash-table. A key, value tuple that has the index with the short code being the key and the value being the long url, so that we can quickly lookup them.

* `http://krz.io/MEd21`
  * Lookup on a Hash Table
    * `MEd21: https://my-long-link.com/a-very-long/path/with/numbers/90999.html`

However, as [this blogpost][1] from Jeff Atwood states: _creating a consistent hashing for this purpose is not a trivial task_.

Let us take a look on how traditional hashing might not be the best idea.

#### Traditional Hashing

We could use standard battle-tested hashing algorithms, let us say `MD5` for such purpose.

Here is the result of hashing the word `example` against the most-known hashing algorithms:

```
CRC32: 5cc22de8
MD5: 1a79a4d60de6718e8e5b326e338ae533
MD4: e1821c366558728f70e054fbf9db7b64
MD2: fd7a532a863c3394b89b38d18cf12073
SHA1: c3499c2729730a7f807efb8676a92dcb6f8a3f8f
SHA224: 312b3e578a63c0a34ed3f359263f01259e5cda07df73771d26928be5
SHA256: 50d858e0985ecc7f60418aaf0cc5ab587f42c2570a884095a9e8ccacd0f6545c
SHA384: feeebf884f6dabe6eca8d68e373d6be488cdaa5eb764e895290336ffe9ff969686f2a9d362e9a8bbddf6e7b2e1455f2d
SHA512: 3bb12eda3c298db5de25597f54d924f2e17e78a26ad8953ed8218ee682f0bbbe9021e2f3009d152c911bf1f25ec683a902714166767afbd8e5bd0fb0124ecb8a
```
> You can do that yourself [here][10]

##### Idempotency

One of the good parts is that such alternative is **idempotent**. Meaning that, if the content (e.g.: an URL) doesn't change, the hash won't change eithere. Hashing the word `example` with this algorithm in any computer would, or should, generate the same result.

Idempotency is good on that sense, because if multiple users try to shorten the same URL, we would **save space and lookup time** by avoiding saving the same hash over and over. We'll discuss those in depth later on.

##### Collision Probabilities

Besides that, such algorithms have [known collision probabilities][11], which guide us on figuring out the capacity and durability of the URLs. e.g.: generating 10M URLs per month, in 2 years the chance of collision will be X.

If you like hashing read more about MD5 collisions [here][12] and [here][11].

##### Length

There is a deal breaker constraint with traditional hashing, which is exactly the reason why collision probabilities are so low, it's the obvious huge length of those hashes.

* SHA512 always return a `512` chars long string.
* MD5  always return a `128` chars long  string.

It defeats the whole purpose, e.g.: `https://krz.io/1a79a4d60de6718e8e5b326e338ae533`

##### The Birthday Paradox

Even using a not so lengthy algorithm, as `CRC32` the string would have around 8 chars which increases the change of collision a lot.

A naive attempt to calculate the collision would be to look at the amount of possibilities by the amount of permutations, that being:

8 random characters from `a-z` and `0-9` give us around 36 different chars, so:

```
n! / (n - r)!
```

where n is the amount of possibilities and n is the amount of samples.

```
n = 36
r = 8

36! / (36 - 8)! = 1.220096908𝐸+12
```
> [Source][14]

That is, `1 trillion 220 billion 96 million 908 thousand 800`, or if we were have 1000 URLs being created every second, we could go on for almost **40 years** before running out of options.

However, the above is not the **collision probability**, 1 in 1 trillion, given to the [birthday paradox][13] that probability is much lower, since the space of possibilities for URLs is so much broader than 1 trillion.

The catch here is that even that we could generate more than 1 trillion different hashes, it would't ensure we would't hit a collision after a few thousand iterations.

## Conclusion

Traditional Hashing is not a good alternative, quoting [Jeff's article][1] once more:

> URL shortening services can't rely on traditional hashing techniques

#### What are the alternatives then?

Jeff's article comes to a good conclusion, to create a production-grade URL shortener, the short alias can't be the hash of the URL, it rather be a brute forced sequence of characters that grows in size over time.

He says:
> Each new URL gets a unique three character combination until no more are left

That way we are not bound to collision probability and we can explore the full space of a given number of characters. Let us say we had a number generator, sequential, and we would use that for converting the number to a different form of representatiion...

```
0 - a
1 - b
2 - c
```

We could go on and on, until we endup having no more characters left, and we start to use 2 charaters. e.g.:

```
25 - aa
26 - ab
27 - ac
```

This approach is much simpler and more performatic. Also, this problem is known by other "names". Other people came to the same conclusion and realised this is useful when you want to expose short and easy to memorise IDs, e.g.: booking codes, 1-time tokens,... but also, this problem is similar to the famous "Youtube Video IDs".

All of that because we don't want to expose the sequencial integer identifiers.

#### Decimal is not safe

The whole point of the "Youtube Way" is that IDs, that are usually integers, follow our standard number system, a decimal (base 10) system.

The decimal system can be unsafe in some ways, because of its predictability, one might easily try to guess "how many videos are on youtube" or even "how many videos are posted every hour on youtube" by simply comparing the IDs of new sample videos posted with 1 hour difference.

In our scenario, the decimal biggest issue is its representability, it's too big, for 1M URLS we would already be using 6 digits.

Every sequence is bound to the size of symbols we use to represent it, its number of characters increases proporcionally to the amount of characters available for use. For example:

* On a decimal (base 10) system, we can represent up to 10 different values with a single char, from 0 to 9. The 11th value has to be represented by "10", which uses 2 characters.
* On a hexadecidemal (base 16) system, we can represent up to 16 different values with a single char, from 0 to F. Here, the 17th value is represented by "10", which uses 2 characters.

* On an alpha-numerical, case sensitive, (base 62), system, we would be able to represent up to **62** different values before having to add a new character.


Base62 alphabet:
```
[a-z] + [A-Z] + [0-9]
 26      26       10  =  62
```

Much better, right?

We can also add other characters, as we'll see next, but for our purpose is important to [respect URL Safe][16] characters.

Given this is a recurrent problem with multiple applications, there are several different solutions available on open-source. It varies from [old school PHP solutions from the early 2000s][17] up to modern and safer standards that can be implemented in any language.

### HashID

HashID is one of the standards out there, the most complete I could find. Their [website][18] states:

> Hashids is a small open-source library that generates short, unique, non-sequential ids from numbers.

Let us dive into it.

##### Base10 to BaseX Convertion

There are 2 main parts to their statement, HashID basically converts a decimal (base 10) number to a base X, where X is the size of the "alphabet" of our alpha-numerical base.

That help us to achieve **astronomical numbers** of different 8-char strings.

e.g.:

* `[a-z] + [0-9]` = `36 chars` > `36^8` = `2 trillion 821 billion 109 million 907 thousand 456`
* `[a-z] + [A-Z] + [0-9]` = `62 chars` > `62^8` = `218 trillion 340 billion 105 million 584 thousand 896`
* `[a-z] + [A-Z] + [0-9] + [$-_.+!*'(),]` (using all URL-safe) = `73 chars` > `73^8` = `806 trillion 460 billion 91 million 894 thousand 81`


Following the previous analogy for CRC32, with around `800 trillion` different permutations,we could generate **10 thousand URLs** per second nonstop, and we could go on for almost **2564 years** before running out of options.

```
(73^8)/(10000*60*60*24*7*52)
```
> [Source][19]

*I think that's more than enough*.

##### Salt, Security and Obfuscation

Interestingly enough, we can also provide a **Salt** to HashID. That creates some entropy to the whole operation, making it difficult to try to decode or "guess" the next/previous values, which is important for security measures, but as well give us the possibility to create more obfuscated IDs.

In simple terms, if we were not using a salt, we would have something like:

```
0 - a
1 - b
2 - c
3 - d
4 - e
5 - f

and so on...
```

With salt, we can say that the alphabet is like `M$29kJ)...`, which would generate a less obvious order:

```
0 - M
1 - $
2 - 2
3 - 9
4 - k
5 - J

and so on...
```

Which helps to prevent the predictability but also to have some control and uniqueness across instances of our application. Imagine that 2 different companies are using it, you don't want to generate URLs in the same order. Each company could use their own unique salt.

## TL;DR

HashID is the best option so far, since:
- Consistent (not random)
- There is no collision probability since it is not a hash
- Grows on demand
- Based on a number
- Offers Salt which provides a nice way to generate unique IDs

*Okay, be honest, what's the catch?*

It's not a catch per say, is more like a dependency we need to take into account. HashIDs is require an extremelly consistent **sequence generator**. The integer that gets converted to a "HashId" must be unique always to ensure consistency.

Let us dive into that too.

### Sequence Generator

There are several ways of implementing an extremelly consistent sequence generators, it will always depend on the type of system you are building and the type of dependencies you want to have. We could implement it with a simple file, with a volatile in-memory record or bring dependencies that deal with that on a more distributed way.

Being more realistic in regards to the current requirements, we can discard file or in-memory options because of the amount of effort on implementing them, sort of re-inventing the wheel there. Options like Redis are interesting because they are indeed consistent, but they are somewhere limited in regards to disk-persistency and clustering...

On our day-jobs we use databases for a lot of things, and most of those things have an ID column, that is most of the times a simple sequence. We could just use that!

The auto-incremental values is exatcly what we need. Adding to that, databases such as PostgreSQL and MySQL have years of battle tested clustering options, preventing us from falling into a [Single Point of Failure][20].

Also, when we think about it, we need to store the data or the URL and its shortlink somewhere, so a database of some sort would endup being a requirement anyway. The requirements for our storage layer would be quite similar too, consistency and clustering to avoid SPOF.

### PostgreSQL Sequences

PostgreSQL has a nice way of creating and managing custom sequences with different costs and benetifs associated to it.

There are 3 types of sequences, e.g.:

| Name        | Storage Size | Range                         |
|-------------|--------------|-------------------------------|
| SMALLSERIAL | 2 bytes      | 1 to 32,767                   |
| SERIAL      | 4 bytes      | 1 to 2,147,483,647            |
| BIGSERIAL   | 8 bytes      | 1 to 922,337,2036,854,775,807 |

We would go for the last one, even though its storage cost is bigger, it gives us room to eventually explore the full-space of URLs, and many many more to come.

It's important to understand that the sequence management is not going to be directly related to the schema management, meaning the tables and storage per say.

We'll likely use PostgreSQL functions to manage the sequence and avoid storing both the integer counter and the string alias version, it would be unnecessary redundancy.

The way you operate a sequence is by using Postgres [create sequence][21] function, e.g.:

```sql
create sequence kurz_sequence;
```

And then operate it by deciding when we need to [increment and get the next value][22], e.g.:

```sql
select nextval('kurz_sequence');
 nextval
---------
       1
```

Let us look on how our storage structure will look like to understand more about it.

## Storage

One of the most important and challenging aspects of the whole project is how to efficiently store and still keep it flexible since we want to be able to built something with a good UX for people hosting it. Even though there are a lot of good reasons to go with a NoSQL databse, Postgres provide us with useful features such as the sequence generator, maturity, and battle tested tooling and consistency.

Kurz is supposed to be easy to run, having complex dependencies could interfere with that goal.

### Schema

There are two main things which we definitely need to store, the long-url and the our encoded short alias. Those are both text or string like fields, and for flexibility we might want to store the creation `timestamp`.

Let's create a simple sketch of how the schema will look like, and dive into what types we should use for each field.

TODO: Explain Expiration

| Field      | Type      |
|------------|-----------|
| short      | text      |
| url        | text      |
| created_at | timestamp |
| expired_at | timestamp |

In order to choose database types we need now to understand the database ones, their trade-offs, evaluating their size and performance implications.

### Capacity Planning

The capacity planning is utterly important here, it will be proportional to your write-traffic. Therefore, it's important to have ideas of how much space is required to store X amount of URLs.

The largest field in size is the full URL, where it's important to be flexible on size, given the web big spectrum on URLs. The maximum URL size seems not to be a common agreement over the web, yet, the number that popped up the most was 2048 bytes.

> The HTTP protocol does not place any a priori limit on the length of a URI. Servers MUST be able to handle the URI of any resource they serve, and SHOULD be able to handle URIs of unbounded length if they provide GET-based forms that could generate such URIs. A server SHOULD return 414 (Request-URI Too Long) status if a URI is longer than the server can handle (see section 10.4.15).
Source: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html

For the Short URL there is a big compromise. Naively, you can thing of it as having the maximum size of your short urls, but it would be limiting to us when trying to create custom URLs, as dicussed before.

e.g.:

`krz.io/my-creative-big-alias` has 21 characters.

Given the large variety of URL sizes, and [how limited-sized text fields work on postgres][28], the `text` field type on Postgres seems to be the best suited type at this point.

Some assumptions:
* `short` - varies from 1 to N chars, we can assume that on average we would have mainly 5 bytes for a long time.
* `url` - varies a lot, up to 2048 chars but let's assume an average of 256 chars as a good compromise.
* `created_at`, `expired_at` - 8 bytes each by default.

e.g.:
*  a 247 long url looks like this: `http://chart.apis.google.com/chart?chs=500x500&chma=0,0,100,100&cht=p&chdl=android%7Cjava%7Cstack-trace%7Cbroadcastreceiver%7Candroid-ndk%7Cuser-agent%7Candroid-webview%7Cwebview%7Cbackground%7Cmultithreading%7Candroid-source%7Csms%7Cadb%7Csollections%7Cactivity`
* a 5 bytes long short version could be like `https://krz.io/Mb99x`, the first 2 billion short urls can be generated with up to 5 characters.

At the end, all of our text types are variable, we can have some simple math to have the order of magnitude of our database depending on our monthly traffic.

| Field      | Type      | Size               | Reference                                           |
|------------|-----------|--------------------|-----------------------------------------------------|
| short      | text      | 5 bytes (on avg)   |  [Analysis Text vs Char][28], [Postgres Manual][29] |
| url        | text      | 256 bytes (on avg) |  [Analysis Text vs Char][28], [Postgres Manual][29] |
| created_at | timestamp | 8 bytes            |  [Postgres Manual][27]                              |
| expired_at | timestamp | 8 bytes            |  [Postgres Manual][27]                              |

### Final Estimates

#### Storage Estimate

At the end, our **avg row size** is around (5 + 256 + 8 + 8) = 277 bytes.

Estimating a traffic of 100M URLs shortned every month, which is roughly around ~50 write req/s.

```
((100M URLs * 277 bytes) / (1024^3)) * 1.2 ~= 30GB
```

Where `1024^3` is the conversion from bytes to GB, and 20% of error-room on the estimation, leading us to around 30GB per month. Assuming we will run the system for more than a month, let us say, 5 years, we could expect:

```
(30GB * 12 months) * 5 years ~= 1.8TB
```

1.8TB, pretty reasonable, considering we would be storing up to **6 Billion** URLs over the course of those 5 years.

#### Cache Estimate

Expecting a `100:1` read-write ratio, meaning that each URL create would have around 100 clicks on average, we would be expecting 5000 read req/s.

With 5k req/s we would be getting around ~500M read requests a day. Considering we don't want to explode our SQL database with read queries, we might want to have a in-memory cache to take the big hit, considering a 60% cache hit for our URLs, given they are quite seasonal, we can calculate how much memory we need on that cache.

```
(((500M reads * 0.6 (60% cache)) * 277) / 1024^3) ~= 80GB
```

Around 80GB of in-memory cache to support our read-load gracefully.

**Note** - the estimates are quite high-level, for demonstration purposes.

## Performance

### Design

###
# Stack

## Backend: Rust

Rust is an extremelly safe statically typed compiled language. The compiler, prevents lot sof ....

Listed here some modern alternatives for rust, and the reason(s) why they're rulled out of this project.

### Haskell

Nothing to levarage from functional programing on the backend, mainly IO manipulation.

### Go

big runtime, GC concerns and such

#### Scala

jvm-based, big memory footprint, high-latency and resource demanding

### C

huge operational overhead

## Frontend: Elm

Elm is a functional.


TODO
  - Name Origin
  - URL Redirection Codes 301/302 ...

---------
[1]: https://blog.codinghorror.com/url-shortening-hashes-in-practice/
[2]: https://www.youtube.com/watch?v=JQDHz72OA3c
[3]: https://michiel.buddingh.eu/distribution-of-hash-values
[4]: https://www.educative.io/collection/page/5668639101419520/5649050225344512/5668600916475904
[5]: https://engineering.checkr.com/introducing-flagr-a-robust-high-performance-service-for-feature-flagging-and-a-b-testing-f037c219b7d5
[6]: https://en.wikipedia.org/wiki/Permalink
[7]: https://github.com/kellegous/go
[9]: https://github.com/marceloboeira/shortify
[10]: http://www.toolsvoid.com/multi-hash-generator
[11]: https://stackoverflow.com/a/288519
[12]: https://crypto.stackexchange.com/a/12679
[13]: https://www.youtube.com/watch?v=KtT_cgMzHx8
[14]: https://www.calculatorsoup.com/calculators/discretemathematics/permutations.php
[15]: https://github.com/marceloboeira/kurz-old
[16]: https://perishablepress.com/stop-using-unsafe-characters-in-urls/
[17]: https://kvz.io/blog/2009/06/10/create-short-ids-with-php-like-youtube-or-tinyurl/
[18]: https://hashids.org/
[19]: https://www.wolframalpha.com/input/?i=(73%5E8)%2F(10000*60*60*24*7*52)
[20]: https://en.wikipedia.org/wiki/Single_point_of_failure
[21]: https://www.postgresql.org/docs/9.5/sql-createsequence.html
[22]: https://www.postgresql.org/docs/9.1/functions-sequence.html
[23]: http://www.dict.cc/deutsch-englisch/kurz.html
[24]: https://github.com/YOURLS/YOURLS
[25]: https://github.com/thedevs-network/kutt
[26]: https://github.com/cydrobolt/polr
[27]: https://www.postgresql.org/docs/9.1/datatype-datetime.html
[28]: https://www.depesz.com/2010/03/02/charx-vs-varcharx-vs-varchar-vs-text/
[29]: https://www.postgresql.org/docs/9.1/datatype-character.html
